module Gitlab
  module Auth
    class MissingPersonalTokenError < StandardError; end

    class << self
      def find_for_git_client(login, password, project:, ip:)
        raise "Must provide an IP for rate limiting" if ip.nil?

        result =
          service_request_check(login, password, project) ||
          build_access_token_check(login, password) ||
          user_with_password_for_git(login, password) ||
          oauth_access_token_check(login, password) ||
          lfs_token_check(login, password) ||
          personal_access_token_check(login, password) ||
          Gitlab::Auth::Result.new

        rate_limit!(ip, success: result.success?, login: login)

        result
      end

      def find_with_user_password(login, password)
        user = User.by_login(login)

        if Devise.omniauth_providers.include?(:kerberos)
          kerberos_user = Gitlab::Kerberos::Authentication.login(login, password)
          return kerberos_user if kerberos_user
        end

        # If no user is found, or it's an LDAP server, try LDAP.
        #   LDAP users are only authenticated via LDAP
        if user.nil? || user.ldap_user?
          # Second chance - try LDAP authentication
          return nil unless Gitlab::LDAP::Config.enabled?

          Gitlab::LDAP::Authentication.login(login, password)
        else
          user if user.valid_password?(password)
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
          if token && token.accessible?
            user = User.find_by(id: token.resource_owner_id)
            Gitlab::Auth::Result.new(user, nil, :oauth, read_authentication_abilities)
          end
        end
      end

      def personal_access_token_check(login, password)
        if login && password
          user = User.find_by_personal_access_token(password)
          validation = User.by_login(login)
          Gitlab::Auth::Result.new(user, nil, :personal_token, full_authentication_abilities) if user.present? && user == validation
        end
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

        Result.new(actor, nil, token_handler.type, authentication_abilities) if Devise.secure_compare(token_handler.value, password)
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
    end
  end
end
