# frozen_string_literal: true

module Gitlab
  module Auth
    MissingPersonalAccessTokenError = Class.new(StandardError)
    IpBlacklisted = Class.new(StandardError)

    # Scopes used for GitLab API access
    API_SCOPES = [:api, :read_user, :read_api].freeze

    # Scopes used for GitLab Repository access
    REPOSITORY_SCOPES = [:read_repository, :write_repository].freeze

    # Scopes used for GitLab Docker Registry access
    REGISTRY_SCOPES = [:read_registry, :write_registry].freeze

    # Scopes used for GitLab as admin
    ADMIN_SCOPES = [:sudo].freeze

    # Scopes used for OpenID Connect
    OPENID_SCOPES = [:openid].freeze

    # OpenID Connect profile scopes
    PROFILE_SCOPES = [:profile, :email].freeze

    # Default scopes for OAuth applications that don't define their own
    DEFAULT_SCOPES = [:api].freeze

    CI_JOB_USER = 'gitlab-ci-token'

    class << self
      prepend_mod_with('Gitlab::Auth') # rubocop: disable Cop/InjectEnterpriseEditionModule

      def omniauth_enabled?
        Gitlab.config.omniauth.enabled
      end

      def find_for_git_client(login, password, project:, ip:)
        raise "Must provide an IP for rate limiting" if ip.nil?

        rate_limiter = Gitlab::Auth::IpRateLimiter.new(ip)

        raise IpBlacklisted if !skip_rate_limit?(login: login) && rate_limiter.banned?

        # `user_with_password_for_git` should be the last check
        # because it's the most expensive, especially when LDAP
        # is enabled.
        result =
          service_request_check(login, password, project) ||
          build_access_token_check(login, password) ||
          lfs_token_check(login, password, project) ||
          oauth_access_token_check(login, password) ||
          personal_access_token_check(password, project) ||
          deploy_token_check(login, password, project) ||
          user_with_password_for_git(login, password) ||
          Gitlab::Auth::Result.new

        rate_limit!(rate_limiter, success: result.success?, login: login)
        look_to_limit_user(result.actor)

        return result if result.success? || authenticate_using_internal_or_ldap_password?

        # If sign-in is disabled and LDAP is not configured, recommend a
        # personal access token on failed auth attempts
        raise Gitlab::Auth::MissingPersonalAccessTokenError
      end

      # Find and return a user if the provided password is valid for various
      # authenticators (OAuth, LDAP, Local Database).
      #
      # Specify `increment_failed_attempts: true` to increment Devise `failed_attempts`.
      # CAUTION: Avoid incrementing failed attempts when authentication falls through
      # different mechanisms, as in `.find_for_git_client`. This may lead to
      # unwanted access locks when the value provided for `password` was actually
      # a PAT, deploy token, etc.
      def find_with_user_password(login, password, increment_failed_attempts: false)
        # Avoid resource intensive checks if login credentials are not provided
        return unless login.present? && password.present?

        # Nothing to do here if internal auth is disabled and LDAP is
        # not configured
        return unless authenticate_using_internal_or_ldap_password?

        Gitlab::Auth::UniqueIpsLimiter.limit_user! do
          user = User.by_login(login)

          break if user && !can_user_login_with_non_expired_password?(user)

          authenticators = []

          if user
            authenticators << Gitlab::Auth::OAuth::Provider.authentication(user, 'database')

            # Add authenticators for all identities if user is not nil
            user&.identities&.each do |identity|
              authenticators << Gitlab::Auth::OAuth::Provider.authentication(user, identity.provider)
            end
          else
            # If no user is provided, try LDAP.
            #   LDAP users are only authenticated via LDAP
            authenticators << Gitlab::Auth::Ldap::Authentication
          end

          authenticators.compact!

          # return found user that was authenticated first for given login credentials
          authenticated_user = authenticators.find do |auth|
            authenticated_user = auth.login(login, password)
            break authenticated_user if authenticated_user
          end

          user_auth_attempt!(user, success: !!authenticated_user) if increment_failed_attempts

          authenticated_user
        end
      end

      private

      def rate_limit!(rate_limiter, success:, login:)
        return if skip_rate_limit?(login: login)

        if success
          # Repeated login 'failures' are normal behavior for some Git clients so
          # it is important to reset the ban counter once the client has proven
          # they are not a 'bad guy'.
          rate_limiter.reset!
        else
          # Register a login failure so that Rack::Attack can block the next
          # request from this IP if needed.
          # This returns true when the failures are over the threshold and the IP
          # is banned.
          if rate_limiter.register_fail!
            Gitlab::AppLogger.info "IP #{rate_limiter.ip} failed to login " \
              "as #{login} but has been temporarily banned from Git auth"
          end
        end
      end

      def skip_rate_limit?(login:)
        CI_JOB_USER == login
      end

      def look_to_limit_user(actor)
        Gitlab::Auth::UniqueIpsLimiter.limit_user!(actor) if actor.is_a?(User)
      end

      def authenticate_using_internal_or_ldap_password?
        Gitlab::CurrentSettings.password_authentication_enabled_for_git? || Gitlab::Auth::Ldap::Config.enabled?
      end

      def service_request_check(login, password, project)
        matched_login = /(?<service>^[a-zA-Z]*-ci)-token$/.match(login)

        return unless project && matched_login.present?

        underscored_service = matched_login['service'].underscore

        return unless Integration.available_integration_names.include?(underscored_service)

        # We treat underscored_service as a trusted input because it is included
        # in the Integration.available_integration_names allowlist.
        accessor = Project.integration_association_name(underscored_service)
        service = project.public_send(accessor) # rubocop:disable GitlabSecurity/PublicSend

        return unless service && service.activated? && service.valid_token?(password)

        Gitlab::Auth::Result.new(nil, project, :ci, build_authentication_abilities)
      end

      def user_with_password_for_git(login, password)
        user = find_with_user_password(login, password)
        return unless user

        raise Gitlab::Auth::MissingPersonalAccessTokenError if user.two_factor_enabled?

        Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, full_authentication_abilities)
      end

      def oauth_access_token_check(login, password)
        if login == "oauth2" && password.present?
          token = Doorkeeper::AccessToken.by_token(password)

          if valid_oauth_token?(token)
            user = User.id_in(token.resource_owner_id).first
            return unless user && can_user_login_with_non_expired_password?(user)

            Gitlab::Auth::Result.new(user, nil, :oauth, full_authentication_abilities)
          end
        end
      end

      def personal_access_token_check(password, project)
        return unless password.present?

        token = PersonalAccessTokensFinder.new(state: 'active').find_by_token(password)

        return unless token

        return unless valid_scoped_token?(token, all_available_scopes)

        if project && token.user.project_bot?
          return unless token_bot_in_project?(token.user, project) || token_bot_in_group?(token.user, project)
        end

        if can_user_login_with_non_expired_password?(token.user) || token.user.project_bot?
          Gitlab::Auth::Result.new(token.user, nil, :personal_access_token, abilities_for_scopes(token.scopes))
        end
      end

      def token_bot_in_project?(user, project)
        project.bots.include?(user)
      end

      # rubocop: disable CodeReuse/ActiveRecord

      # A workaround for adding group-level automation is to add the bot user of a project access token as a group member.
      # In order to make project access tokens work this way during git authentication, we need to add an additional check for group membership.
      # This is a temporary workaround until service accounts are implemented.
      def token_bot_in_group?(user, project)
        project.group && project.group.members_with_parents.where(user_id: user.id).exists?
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def valid_oauth_token?(token)
        token && token.accessible? && valid_scoped_token?(token, [:api])
      end

      def valid_scoped_token?(token, scopes)
        AccessTokenValidationService.new(token).include_any_scope?(scopes)
      end

      def abilities_for_scopes(scopes)
        abilities_by_scope = {
          api: full_authentication_abilities,
          read_api: read_only_authentication_abilities,
          read_registry: [:read_container_image],
          write_registry: [:create_container_image],
          read_repository: [:download_code],
          write_repository: [:download_code, :push_code]
        }

        scopes.flat_map do |scope|
          abilities_by_scope.fetch(scope.to_sym, [])
        end.uniq
      end

      def deploy_token_check(login, password, project)
        return unless password.present?

        token = DeployToken.active.find_by_token(password)

        return unless token && login
        return if login != token.username

        # Registry access (with jwt) does not have access to project
        return if project && !token.has_access_to?(project)
        # When repository is disabled, no resources are accessible via Deploy Token
        return if project&.repository_access_level == ::ProjectFeature::DISABLED

        scopes = abilities_for_scopes(token.scopes)

        if valid_scoped_token?(token, all_available_scopes)
          Gitlab::Auth::Result.new(token, project, :deploy_token, scopes)
        end
      end

      def lfs_token_check(login, encoded_token, project)
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
            read_write_project_authentication_abilities
          elsif token_handler.deploy_key_pushable?(project)
            read_write_authentication_abilities
          else
            read_only_authentication_abilities
          end

        if token_handler.token_valid?(encoded_token)
          Gitlab::Auth::Result.new(actor, nil, token_handler.type, authentication_abilities)
        end
      end

      def build_access_token_check(login, password)
        return unless login == CI_JOB_USER
        return unless password

        build = find_build_by_token(password)
        return unless build
        return unless build.project.builds_enabled?

        if build.user
          return unless can_user_login_with_non_expired_password?(build.user) || (build.user.project_bot? && build.project.bots&.include?(build.user))

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
          :build_create_container_image,
          :build_destroy_container_image
        ]
      end

      def read_only_project_authentication_abilities
        [
          :read_project,
          :download_code
        ]
      end

      def read_write_project_authentication_abilities
        read_only_project_authentication_abilities + [
          :push_code
        ]
      end

      def read_only_authentication_abilities
        read_only_project_authentication_abilities + [
          :read_container_image
        ]
      end

      def read_write_authentication_abilities
        read_only_authentication_abilities + [
          :push_code,
          :create_container_image
        ]
      end

      def full_authentication_abilities
        read_write_authentication_abilities + [
          :admin_container_image
        ]
      end

      def available_scopes_for(current_user)
        scopes = non_admin_available_scopes
        scopes += ADMIN_SCOPES if current_user.admin?
        scopes
      end

      def all_available_scopes
        non_admin_available_scopes + ADMIN_SCOPES
      end

      # Other available scopes
      def optional_scopes
        all_available_scopes + OPENID_SCOPES + PROFILE_SCOPES - DEFAULT_SCOPES
      end

      def registry_scopes
        return [] unless Gitlab.config.registry.enabled

        REGISTRY_SCOPES
      end

      def resource_bot_scopes
        Gitlab::Auth::API_SCOPES + Gitlab::Auth::REPOSITORY_SCOPES + Gitlab::Auth.registry_scopes - [:read_user]
      end

      private

      def non_admin_available_scopes
        API_SCOPES + REPOSITORY_SCOPES + registry_scopes
      end

      def find_build_by_token(token)
        ::Gitlab::Database::LoadBalancing::Session.current.use_primary do
          ::Ci::AuthJobFinder.new(token: token).execute
        end
      end

      def user_auth_attempt!(user, success:)
        return unless user && Gitlab::Database.main.read_write?
        return user.unlock_access! if success

        user.increment_failed_attempts!
      end

      def can_user_login_with_non_expired_password?(user)
        user.can?(:log_in) && !user.password_expired_if_applicable?
      end
    end
  end
end
