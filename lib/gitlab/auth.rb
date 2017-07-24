module Gitlab
  module Auth
    MissingPersonalTokenError = Class.new(StandardError)

    REGISTRY_SCOPES = [:read_registry].freeze

    # Scopes used for GitLab API access
    API_SCOPES = [:api, :read_user].freeze

    # Scopes used for OpenID Connect
    OPENID_SCOPES = [:openid].freeze

    # Default scopes for OAuth applications that don't define their own
    DEFAULT_SCOPES = [:api].freeze

    AVAILABLE_SCOPES = (API_SCOPES + REGISTRY_SCOPES).freeze

    # Other available scopes
    OPTIONAL_SCOPES = (AVAILABLE_SCOPES + OPENID_SCOPES - DEFAULT_SCOPES).freeze

    class << self
      prepend EE::Gitlab::Auth

      def find_for_git_client(login, password, project:, ip:)
        raise "Must provide an IP for rate limiting" if ip.nil?

        # `user_with_password_for_git` should be the last check
        # because it's the most expensive, especially when LDAP
        # is enabled.
        result =
          service_request_check(login, password, project) ||
          build_access_token_check(login, password) ||
          lfs_token_check(login, password) ||
          oauth_access_token_check(login, password) ||
          personal_access_token_check(password) ||
          user_with_password_for_git(login, password) ||
          Gitlab::Auth::Result.new

        rate_limit!(ip, success: result.success?, login: login)
        Gitlab::Auth::UniqueIpsLimiter.limit_user!(result.actor)

        return result if result.success? || current_application_settings.password_authentication_enabled? || Gitlab::LDAP::Config.enabled?

        # If sign-in is disabled and LDAP is not configured, recommend a
        # personal access token on failed auth attempts
        raise Gitlab::Auth::MissingPersonalTokenError
      end

      def find_with_user_password(login, password)
        # Avoid resource intensive login checks if password is not provided
        return unless password.present?

        # Nothing to do here if internal auth is disabled and LDAP is
        # not configured
        return unless current_application_settings.password_authentication_enabled? || Gitlab::LDAP::Config.enabled?

        Gitlab::Auth::UniqueIpsLimiter.limit_user! do
          user = User.by_login(login)

          # If no user is found, or it's an LDAP server, try LDAP.
          #   LDAP users are only authenticated via LDAP
          if user.nil? || user.ldap_user?
            # Second chance - try LDAP authentication
            return unless Gitlab::LDAP::Config.enabled?

            Gitlab::LDAP::Authentication.login(login, password)
          else
            user if user.active? && user.valid_password?(password)
          end
        end
      end

      def rate_limit!(ip, success:, login:)
        rate_limiter = Gitlab::Auth::IpRateLimiter.new(ip)
        return unless rate_limiter.enabled?

        if success
          # Repeated login 'failures' are normal behavior for some Git clients so
          # it is important to reset the ban counter once the client has proven
          # they are not a 'bad guy'.
          rate_limiter.reset!
        else
          # Register a login failure so that Rack::Attack can block the next
          # request from this IP if needed.
          rate_limiter.register_fail!

          if rate_limiter.banned?
            Rails.logger.info "IP #{ip} failed to login " \
              "as #{login} but has been temporarily banned from Git auth"
          end
        end
      end

      private

      def service_request_check(login, password, project)
        matched_login = /(?<service>^[a-zA-Z]*-ci)-token$/.match(login)

        return unless project && matched_login.present?

        underscored_service = matched_login['service'].underscore

        if Service.available_services_names.include?(underscored_service)
          # We treat underscored_service as a trusted input because it is included
          # in the Service.available_services_names whitelist.
          service = project.public_send("#{underscored_service}_service")

          if service && service.activated? && service.valid_token?(password)
            Gitlab::Auth::Result.new(nil, project, :ci, build_authentication_abilities)
          end
        end
      end

      def user_with_password_for_git(login, password)
        user = find_with_user_password(login, password)
        return unless user

        raise Gitlab::Auth::MissingPersonalTokenError if user.two_factor_enabled?

        Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, full_authentication_abilities)
      end

      def oauth_access_token_check(login, password)
        if login == "oauth2" && password.present?
          token = Doorkeeper::AccessToken.by_token(password)

          if valid_oauth_token?(token)
            user = User.find_by(id: token.resource_owner_id)
            Gitlab::Auth::Result.new(user, nil, :oauth, full_authentication_abilities)
          end
        end
      end

      def personal_access_token_check(password)
        return unless password.present?

        token = PersonalAccessTokensFinder.new(state: 'active').find_by(token: password)

        if token && valid_scoped_token?(token, AVAILABLE_SCOPES)
          Gitlab::Auth::Result.new(token.user, nil, :personal_token, abilities_for_scope(token.scopes))
        end
      end

      def valid_oauth_token?(token)
        token && token.accessible? && valid_scoped_token?(token, [:api])
      end

      def valid_scoped_token?(token, scopes)
        AccessTokenValidationService.new(token).include_any_scope?(scopes)
      end

      def abilities_for_scope(scopes)
        scopes.map do |scope|
          self.public_send(:"#{scope}_scope_authentication_abilities")
        end.flatten.uniq
      end

      def lfs_token_check(login, password)
        deploy_key_matches = login.match(/\Alfs\+deploy-key-(\d+)\z/)

        actor =
          if deploy_key_matches
            DeployKey.find(deploy_key_matches[1])
          else
            User.by_login(login)
          end

        return unless actor

        token_handler = Gitlab::LfsToken.new(actor)

        authentication_abilities =
          if token_handler.user?
            full_authentication_abilities
          else
            read_authentication_abilities
          end

        if Devise.secure_compare(token_handler.token, password)
          Gitlab::Auth::Result.new(actor, nil, token_handler.type, authentication_abilities)
        end
      end

      def build_access_token_check(login, password)
        return unless login == 'gitlab-ci-token'
        return unless password

        build = ::Ci::Build.running.find_by_token(password)
        return unless build
        return unless build.project.builds_enabled?

        if build.user
          # If user is assigned to build, use restricted credentials of user
          Gitlab::Auth::Result.new(build.user, build.project, :build, build_authentication_abilities)
        else
          # Otherwise use generic CI credentials (backward compatibility)
          Gitlab::Auth::Result.new(nil, build.project, :ci, build_authentication_abilities)
        end
      end

      public

      def build_authentication_abilities
        [
          :read_project,
          :build_download_code,
          :build_read_container_image,
          :build_create_container_image
        ]
      end

      def read_authentication_abilities
        [
          :read_project,
          :download_code,
          :read_container_image
        ]
      end

      def full_authentication_abilities
        read_authentication_abilities + [
          :push_code,
          :create_container_image
        ]
      end
      alias_method :api_scope_authentication_abilities, :full_authentication_abilities

      def read_registry_scope_authentication_abilities
        [:read_container_image]
      end

      # The currently used auth method doesn't allow any actions for this scope
      def read_user_scope_authentication_abilities
        []
      end
    end
  end
end
