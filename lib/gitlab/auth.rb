# frozen_string_literal: true

module Gitlab
  module Auth
    MissingPersonalAccessTokenError = Class.new(StandardError)

    # Scopes used for GitLab internal API (Kubernetes cluster access)
    K8S_PROXY_SCOPE = :k8s_proxy

    # Scopes used for token allowed to rotate themselves
    SELF_ROTATE_SCOPE = :self_rotate

    # Scopes used for GitLab API access
    API_SCOPE = :api
    READ_API_SCOPE = :read_api
    READ_USER_SCOPE = :read_user
    CREATE_RUNNER_SCOPE = :create_runner
    MANAGE_RUNNER_SCOPE = :manage_runner
    API_SCOPES = [
      API_SCOPE, READ_API_SCOPE,
      READ_USER_SCOPE,
      CREATE_RUNNER_SCOPE, MANAGE_RUNNER_SCOPE,
      K8S_PROXY_SCOPE,
      SELF_ROTATE_SCOPE
    ].freeze

    # Scopes for Duo
    AI_FEATURES = :ai_features
    AI_FEATURES_SCOPES = [AI_FEATURES].freeze
    AI_WORKFLOW = :ai_workflows
    AI_WORKFLOW_SCOPES = [AI_WORKFLOW].freeze
    DYNAMIC_USER = :"user:*"
    DYNAMIC_SCOPES = [DYNAMIC_USER].freeze

    PROFILE_SCOPE = :profile
    EMAIL_SCOPE = :email
    OPENID_SCOPE = :openid
    # Scopes used for OpenID Connect
    OPENID_SCOPES = [OPENID_SCOPE].freeze
    # OpenID Connect profile scopes
    PROFILE_SCOPES = [PROFILE_SCOPE, EMAIL_SCOPE].freeze

    # Scopes used for GitLab Repository access
    READ_REPOSITORY_SCOPE = :read_repository
    WRITE_REPOSITORY_SCOPE = :write_repository
    REPOSITORY_SCOPES = [READ_REPOSITORY_SCOPE, WRITE_REPOSITORY_SCOPE].freeze

    # Scopes used for GitLab Docker Registry access
    READ_REGISTRY_SCOPE = :read_registry
    WRITE_REGISTRY_SCOPE = :write_registry
    REGISTRY_SCOPES = [READ_REGISTRY_SCOPE, WRITE_REGISTRY_SCOPE].freeze

    # Scopes used for Virtual Registry access
    READ_VIRTUAL_REGISTRY_SCOPE = :read_virtual_registry
    WRITE_VIRTUAL_REGISTRY_SCOPE = :write_virtual_registry
    VIRTUAL_REGISTRY_SCOPES = [
      READ_VIRTUAL_REGISTRY_SCOPE, WRITE_VIRTUAL_REGISTRY_SCOPE
    ].freeze

    # Scopes used for GitLab Observability access which is outside of the GitLab app itself.
    # Hence the lack of ability mapping in `abilities_for_scopes`.
    READ_OBSERVABILITY_SCOPE = :read_observability
    WRITE_OBSERVABILITY_SCOPE = :write_observability
    OBSERVABILITY_SCOPES = [READ_OBSERVABILITY_SCOPE, WRITE_OBSERVABILITY_SCOPE].freeze

    # Scopes for Monitor access
    READ_SERVICE_PING_SCOPE = :read_service_ping

    # Scopes used for GitLab as admin
    SUDO_SCOPE = :sudo
    ADMIN_MODE_SCOPE = :admin_mode
    ADMIN_SCOPES = [SUDO_SCOPE, ADMIN_MODE_SCOPE, READ_SERVICE_PING_SCOPE].freeze

    Q_SCOPES = [API_SCOPE, REPOSITORY_SCOPES].flatten.freeze

    # Default scopes for OAuth applications that don't define their own
    DEFAULT_SCOPES = [API_SCOPE].freeze

    CI_JOB_USER = 'gitlab-ci-token'

    class << self
      prepend_mod_with('Gitlab::Auth') # rubocop: disable Cop/InjectEnterpriseEditionModule

      def omniauth_enabled?
        Gitlab.config.omniauth.enabled
      end

      def find_for_git_client(login, password, project:, request:)
        raise "Must provide an IP for rate limiting" if request.ip.nil?

        rate_limiter = Gitlab::Auth::IpRateLimiter.new(request.ip)

        raise IpBlocked if !skip_rate_limit?(login: login) && rate_limiter.banned?

        # `user_with_password_for_git` should be the last check
        # because it's the most expensive, especially when LDAP
        # is enabled.
        result =
          service_request_check(login, password, project) ||
          build_access_token_check(login, password) ||
          lfs_token_check(login, password, project, request) ||
          oauth_access_token_check(password) ||
          personal_access_token_check(password, project) ||
          deploy_token_check(login, password, project) ||
          user_with_password_for_git(login, password) ||
          Gitlab::Auth::Result::EMPTY

        rate_limit!(rate_limiter, success: result.success?, login: login, request: request)
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
          user = User.find_by_login(login)

          break if user && !user.can_log_in_with_non_expired_password?

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

      def rate_limit!(rate_limiter, success:, login:, request:)
        return if skip_rate_limit?(login: login)

        if success
          # Repeated login 'failures' are normal behavior for some Git clients so
          # it is important to reset the ban counter once the client has proven
          # they are not a 'bad guy'.
          rate_limiter.reset!
        elsif rate_limiter.register_fail!
          # Register a login failure so that Rack::Attack can block the next
          # request from this IP if needed.
          # This returns true when the failures are over the threshold and the IP
          # is banned.

          message = "Rack_Attack: Git auth failures has exceeded the threshold. " \
            "IP has been temporarily banned from Git auth."

          Gitlab::AuthLogger.error(
            message: message,
            env: :blocklist,
            remote_ip: request.ip,
            request_method: request.request_method,
            path: request.filtered_path,
            login: login
          )
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

        verifier = TwoFactorAuthVerifier.new(user)

        if user.two_factor_enabled? || verifier.two_factor_authentication_enforced?
          raise Gitlab::Auth::MissingPersonalAccessTokenError
        end

        Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, full_authentication_abilities)
      end

      def oauth_access_token_check(password)
        if password.present?
          token = OauthAccessToken.by_token(password)

          if valid_oauth_token?(token)
            identity = ::Gitlab::Auth::Identity.link_from_oauth_token(token)
            return if identity && !identity.valid?

            user = User.id_in(token.resource_owner_id).first
            return unless user && user.can_log_in_with_non_expired_password?

            Gitlab::Auth::Result.new(user, nil, :oauth, abilities_for_scopes(token.scopes))
          end
        end
      end

      def personal_access_token_check(password, project)
        return unless password.present?

        finder_options = { state: 'active' }
        finder_options[:impersonation] = false unless Gitlab.config.gitlab.impersonation_enabled

        token = PersonalAccessTokensFinder.new(finder_options).find_by_token(password)

        return unless token

        return unless valid_scoped_token?(token, all_available_scopes)

        if project && (token.user.project_bot? || token.user.service_account?)
          return unless can_read_project?(token.user, project)
        end

        if token.user.can_log_in_with_non_expired_password? || (token.user.project_bot? || token.user.service_account?)
          ::PersonalAccessTokens::LastUsedService.new(token).execute

          Gitlab::Auth::Result.new(token.user, nil, :personal_access_token, abilities_for_scopes(token.scopes))
        end
      end

      def can_read_project?(user, project)
        user.can?(:read_project, project)
      end

      def bot_user_can_read_project?(user, project)
        (user.project_bot? || user.service_account? || user.security_policy_bot?) && can_read_project?(user, project)
      end

      def valid_oauth_token?(token)
        token && token.accessible? && valid_scoped_token?(token, Doorkeeper.configuration.scopes)
      end

      def valid_scoped_token?(token, scopes)
        AccessTokenValidationService.new(token).include_any_scope?(scopes)
      end

      def abilities_for_scopes(scopes)
        abilities_by_scope = {
          api: full_authentication_abilities,
          read_api: read_only_authentication_abilities,
          read_registry: %i[read_container_image],
          write_registry: %i[create_container_image],
          read_virtual_registry: %i[read_dependency_proxy],
          write_virtual_registry: %i[write_dependency_proxy],
          read_repository: %i[download_code],
          write_repository: %i[download_code push_code],
          create_runner: %i[create_instance_runner create_runner],
          manage_runner: %i[assign_runner update_runner delete_runner],
          ai_workflows: %i[push_code download_code]
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

      def lfs_token_check(login, encoded_token, project, request)
        return unless login
        return unless git_lfs_request?(request)

        deploy_key_matches = login.match(/\Alfs\+deploy-key-(\d+)\z/)

        actor =
          if deploy_key_matches
            DeployKey.find(deploy_key_matches[1])
          else
            User.find_by_login(login)
          end

        return unless actor

        token_handler = Gitlab::LfsToken.new(actor, project)

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
          return unless build.user.can_log_in_with_non_expired_password? || bot_user_can_read_project?(build.user, build.project)

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
          :build_push_code,
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

      def available_scopes_for(resource)
        available_scopes_for_resource(resource) - unavailable_scopes_for_resource(resource)
      end

      def all_available_scopes
        non_admin_available_scopes + ADMIN_SCOPES
      end

      # Other available scopes
      def optional_scopes
        all_available_scopes + OPENID_SCOPES + PROFILE_SCOPES + AI_WORKFLOW_SCOPES + DYNAMIC_SCOPES - DEFAULT_SCOPES
      end

      def registry_scopes
        return [] unless Gitlab.config.registry.enabled

        REGISTRY_SCOPES
      end

      def virtual_registry_scopes
        return [] unless Gitlab.config.dependency_proxy.enabled

        VIRTUAL_REGISTRY_SCOPES
      end

      def resource_bot_scopes
        non_admin_available_scopes - [READ_USER_SCOPE]
      end

      private

      def git_lfs_request?(request)
        Gitlab::PathRegex.repository_git_lfs_route_regex.match?(request.path)
      end

      def available_scopes_for_resource(resource)
        case resource
        when User
          scopes = non_admin_available_scopes

          if resource.admin? # rubocop: disable Cop/UserAdmin
            scopes += ADMIN_SCOPES
          end

          scopes
        when Project, Group
          resource_bot_scopes
        else
          []
        end
      end

      def unavailable_scopes_for_resource(resource)
        unavailable_ai_features_scopes +
          unavailable_observability_scopes_for_resource(resource)
      end

      def unavailable_ai_features_scopes
        AI_WORKFLOW_SCOPES
      end

      def unavailable_observability_scopes_for_resource(resource)
        return [] if (resource.is_a?(Project) || resource.is_a?(Group)) &&
          Gitlab::Observability.should_enable_observability_auth_scopes?(resource)

        OBSERVABILITY_SCOPES
      end

      def non_admin_available_scopes
        API_SCOPES + REPOSITORY_SCOPES + registry_scopes + virtual_registry_scopes + OBSERVABILITY_SCOPES + AI_FEATURES_SCOPES
      end

      def find_build_by_token(token)
        ::Gitlab::Database::LoadBalancing::SessionMap
          .with_sessions([::ApplicationRecord, ::Ci::ApplicationRecord]).use_primary do
          ::Ci::AuthJobFinder.new(token: token).execute
        end
      end

      def user_auth_attempt!(user, success:)
        return unless user && Gitlab::Database.read_write?
        return user.unlock_access! if success

        user.increment_failed_attempts!
      end
    end
  end
end

Gitlab::Auth.prepend_mod_with('Gitlab::Auth')
