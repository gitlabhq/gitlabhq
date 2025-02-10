# frozen_string_literal: true

module Gitlab
  module Auth
    AuthenticationError = Class.new(StandardError)
    MissingTokenError = Class.new(AuthenticationError)
    TokenNotFoundError = Class.new(AuthenticationError)
    ExpiredError = Class.new(AuthenticationError)
    RevokedError = Class.new(AuthenticationError)
    ImpersonationDisabled = Class.new(AuthenticationError)
    UnauthorizedError = Class.new(AuthenticationError)

    class DpopValidationError < AuthenticationError
      def initialize(msg)
        super("DPoP validation error: #{msg}")
      end
    end

    class InsufficientScopeError < AuthenticationError
      attr_reader :scopes

      def initialize(scopes)
        @scopes = scopes.map { |s| s.try(:name) || s }
      end
    end

    module AuthFinders
      include Gitlab::Utils::StrongMemoize
      include ActionController::HttpAuthentication::Basic
      include ActionController::HttpAuthentication::Token

      PRIVATE_TOKEN_HEADER = 'HTTP_PRIVATE_TOKEN'
      PRIVATE_TOKEN_PARAM = :private_token
      JOB_TOKEN_HEADER = 'HTTP_JOB_TOKEN'
      JOB_TOKEN_PARAM = :job_token
      DEPLOY_TOKEN_HEADER = 'HTTP_DEPLOY_TOKEN'
      RUNNER_TOKEN_PARAM = :token
      RUNNER_JOB_TOKEN_PARAM = :token
      PATH_DEPENDENT_FEED_TOKEN_REGEX = /\A#{User::FEED_TOKEN_PREFIX}(\h{64})-(\d+)\z/

      PARAM_TOKEN_KEYS = [
        PRIVATE_TOKEN_PARAM,
        JOB_TOKEN_PARAM,
        RUNNER_JOB_TOKEN_PARAM
      ].map(&:to_s).freeze
      HEADER_TOKEN_KEYS = [
        PRIVATE_TOKEN_HEADER,
        JOB_TOKEN_HEADER,
        DEPLOY_TOKEN_HEADER
      ].freeze

      # Check the Rails session for valid authentication details
      def find_user_from_warden
        current_request.env['warden']&.authenticate if verified_request?
      end

      def find_user_from_static_object_token(request_format)
        return unless valid_static_objects_format?(request_format)

        token = current_request.params[:token].presence || current_request.headers['X-Gitlab-Static-Object-Token'].presence
        return unless token

        User.find_by_static_object_token(token.to_s) || raise(UnauthorizedError)
      end

      def find_user_from_feed_token(request_format)
        return unless valid_rss_format?(request_format)
        return if Gitlab::CurrentSettings.disable_feed_token

        # NOTE: feed_token was renamed from rss_token but both needs to be supported because
        #       users might have already added the feed to their RSS reader before the rename
        token = current_request.params[:feed_token].presence || current_request.params[:rss_token].presence
        return unless token

        find_feed_token_user(token) || raise(UnauthorizedError)
      end

      def find_user_from_bearer_token
        find_user_from_job_bearer_token || find_user_from_access_token
      end

      def find_user_from_job_token
        return unless route_authentication_setting[:job_token_allowed]

        user = find_user_from_job_token_basic_auth if can_authenticate_job_token_basic_auth?
        return user if user

        find_user_from_job_token_query_params_or_header if can_authenticate_job_token_request?
      end

      def find_user_from_basic_auth_password
        return unless has_basic_credentials?(current_request)

        login, password = user_name_and_password(current_request)
        return if ::Gitlab::Auth::CI_JOB_USER == login

        Gitlab::Auth.find_with_user_password(login.to_s, password.to_s)
      end

      def find_user_from_lfs_token
        return unless has_basic_credentials?(current_request)

        login, token = user_name_and_password(current_request)
        user = User.find_by_login(login.to_s)

        user if user && Gitlab::LfsToken.new(user, nil).token_valid?(token.to_s)
      end

      def find_user_from_personal_access_token
        return unless access_token

        validate_and_save_access_token!

        access_token&.user || raise(UnauthorizedError)
      end

      # We allow private access tokens with `api` scope to be used by web
      # requests on RSS feeds or ICS files for backwards compatibility.
      # It is also used by GraphQL/API requests.
      # And to allow accessing /archive programatically as it was a big pain point
      # for users https://gitlab.com/gitlab-org/gitlab/-/issues/28978.
      # Used for release downloading as well
      def find_user_from_web_access_token(request_format, scopes: [:api])
        return unless access_token && valid_web_access_format?(request_format)

        validate_and_save_access_token!(scopes: scopes)

        ::PersonalAccessTokens::LastUsedService.new(access_token).execute

        access_token.user || raise(UnauthorizedError)
      end

      def find_user_from_access_token
        return unless access_token

        validate_and_save_access_token!

        ::PersonalAccessTokens::LastUsedService.new(access_token).execute

        access_token.user || raise(UnauthorizedError)
      end

      # This returns a deploy token, not a user since a deploy token does not
      # belong to a user.
      #
      # deploy tokens are accepted with deploy token headers and basic auth headers
      def deploy_token_from_request
        return unless route_authentication_setting[:deploy_token_allowed]
        return unless Gitlab::ExternalAuthorization.allow_deploy_tokens_and_deploy_keys?

        token = current_request.env[DEPLOY_TOKEN_HEADER].presence || parsed_oauth_token

        if has_basic_credentials?(current_request)
          _, token = user_name_and_password(current_request)
        end

        deploy_token = DeployToken.active.find_by_token(token.to_s)
        @current_authenticated_deploy_token = deploy_token # rubocop:disable Gitlab/ModuleWithInstanceVariables

        deploy_token
      end

      def cluster_agent_token_from_authorization_token
        return unless route_authentication_setting[:cluster_agent_token_allowed]

        # We are migrating from the `Authorization` header to one specific to cluster
        # agents, `Gitlab-Agentk-Api-Request`. Both must be supported until KAS has
        # been updated to use the new header, and then this first lookup can be removed.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/406582.
        token, _ = if current_request.authorization.present?
                     token_and_options(current_request)
                   else
                     current_request.headers[Gitlab::Kas::INTERNAL_API_AGENTK_REQUEST_HEADER]
                   end

        return unless token.present?

        ::Clusters::AgentToken.active.find_by_token(token.to_s)
      end

      def find_runner_from_token
        return unless api_request?

        token = current_request.params[RUNNER_TOKEN_PARAM].presence
        return unless token

        ::Ci::Runner.find_by_token(token.to_s) || raise(UnauthorizedError)
      end

      def validate_and_save_access_token!(scopes: [], save_auth_context: true)
        # return early if we've already authenticated via a job token
        return if @current_authenticated_job.present? # rubocop:disable Gitlab/ModuleWithInstanceVariables

        # return early if we've already authenticated via a deploy token
        return if @current_authenticated_deploy_token.present? # rubocop:disable Gitlab/ModuleWithInstanceVariables

        return unless access_token

        case AccessTokenValidationService.new(access_token, request: request).validate(scopes: scopes)
        when AccessTokenValidationService::INSUFFICIENT_SCOPE
          save_auth_failure_in_application_context(access_token, :insufficient_scope, scopes) if save_auth_context
          raise InsufficientScopeError, scopes
        when AccessTokenValidationService::EXPIRED
          save_auth_failure_in_application_context(access_token, :token_expired, scopes) if save_auth_context
          raise ExpiredError
        when AccessTokenValidationService::REVOKED
          save_auth_failure_in_application_context(access_token, :token_revoked, scopes) if save_auth_context
          revoke_token_family(access_token)

          raise RevokedError
        when AccessTokenValidationService::IMPERSONATION_DISABLED
          save_auth_failure_in_application_context(access_token, :impersonation_disabled, scopes) if save_auth_context
          raise ImpersonationDisabled
        end

        save_current_token_in_env
      end

      def authentication_token_present?
        PARAM_TOKEN_KEYS.intersection(current_request.params.keys).any? ||
          HEADER_TOKEN_KEYS.intersection(current_request.env.keys).any? ||
          parsed_oauth_token.present?
      end

      private

      def extract_personal_access_token
        current_request.params[PRIVATE_TOKEN_PARAM].presence ||
          current_request.env[PRIVATE_TOKEN_HEADER].presence ||
          parsed_oauth_token
      end

      def save_current_token_in_env
        ::Current.token_info = {
          token_id: access_token.id,
          token_type: access_token.class.to_s,
          token_scopes: access_token.scopes.map(&:to_sym)
        }
      end

      def save_auth_failure_in_application_context(access_token, cause, requested_scopes)
        Gitlab::ApplicationContext.push(
          auth_fail_reason: cause.to_s,
          auth_fail_token_id: "#{access_token.class}/#{access_token.id}",
          auth_fail_requested_scopes: requested_scopes.join(' ')
        )
      end

      def find_user_from_job_bearer_token
        return unless route_authentication_setting[:job_token_allowed]

        token = parsed_oauth_token
        return unless token

        job = ::Ci::AuthJobFinder.new(token: token).execute
        return unless job

        @current_authenticated_job = job # rubocop:disable Gitlab/ModuleWithInstanceVariables

        job.user
      end

      def route_authentication_setting
        return {} unless respond_to?(:route_setting)

        route_setting(:authentication) || {}
      end

      def access_token
        strong_memoize(:access_token) do
          # Kubernetes API OAuth header is not OauthAccessToken or PersonalAccessToken
          # and should be ignored by this method. When the kubernetes API uses a different
          # header, we can remove this guard
          # https://gitlab.com/gitlab-org/gitlab/-/issues/406582
          next if current_request.path.starts_with? "/api/v4/internal/kubernetes/"

          if try(:namespace_inheritable, :authentication)
            access_token_from_namespace_inheritable
          else
            # The token can be a PAT or an OAuth (doorkeeper) token
            begin
              find_oauth_access_token
            rescue UnauthorizedError
              # It is also possible that a PAT is encapsulated in a `Bearer` OAuth token
              # (e.g. NPM client registry auth). In that case, we rescue UnauthorizedError
              # and try to find a personal access token.
            end || find_personal_access_token
          end
        end
      end

      def find_personal_access_token
        token = extract_personal_access_token
        return unless token

        # Expiration, revocation and scopes are verified in `validate_access_token!`
        PersonalAccessToken.find_by_token(token.to_s) || raise(UnauthorizedError)
      end

      def find_oauth_access_token
        token = parsed_oauth_token
        return unless token

        # Expiration, revocation and scopes are verified in `validate_access_token!`
        oauth_token = OauthAccessToken.by_token(token)
        raise UnauthorizedError unless oauth_token

        oauth_token.revoke_previous_refresh_token!

        ::Gitlab::Auth::Identity.link_from_oauth_token(oauth_token).tap do |identity|
          raise UnauthorizedError if identity && !identity.valid?
        end

        oauth_token
      end

      def find_personal_access_token_from_http_basic_auth
        return unless route_authentication_setting[:basic_auth_personal_access_token]
        return unless has_basic_credentials?(current_request)

        _username, password = user_name_and_password(current_request)
        PersonalAccessToken.find_by_token(password.to_s)
      end

      def find_feed_token_user(token)
        token = token.to_s
        find_user_from_path_feed_token(token) || User.find_by_feed_token(token)
      end

      def find_user_from_path_feed_token(token)
        glft = token.match(PATH_DEPENDENT_FEED_TOKEN_REGEX)

        return unless glft

        # make sure that user id uses decimal notation
        user_id = glft[2].to_i(10)
        digest = glft[1]

        user = User.find_by_id(user_id)
        return unless user

        feed_token = user.feed_token
        our_digest = OpenSSL::HMAC.hexdigest("SHA256", feed_token, current_request.path)

        return unless ActiveSupport::SecurityUtils.secure_compare(digest, our_digest)

        user
      end

      def can_authenticate_job_token_basic_auth?
        setting = route_authentication_setting[:job_token_allowed]
        Array.wrap(setting).include?(:basic_auth)
      end

      def can_authenticate_job_token_request?
        setting = route_authentication_setting[:job_token_allowed]
        setting == true || Array.wrap(setting).include?(:request)
      end

      def find_user_from_job_token_query_params_or_header
        token = current_request.params[JOB_TOKEN_PARAM].presence ||
          current_request.params[RUNNER_JOB_TOKEN_PARAM].presence ||
          current_request.env[JOB_TOKEN_HEADER].presence
        return unless token

        job = find_valid_running_job_by_token!(token.to_s)
        @current_authenticated_job = job # rubocop:disable Gitlab/ModuleWithInstanceVariables

        job.user
      end

      def find_user_from_job_token_basic_auth
        return unless has_basic_credentials?(current_request)

        login, password = user_name_and_password(current_request)
        return unless login.present? && password.present?
        return unless ::Gitlab::Auth::CI_JOB_USER == login

        job = find_valid_running_job_by_token!(password.to_s)
        @current_authenticated_job = job # rubocop:disable Gitlab/ModuleWithInstanceVariables

        job.user
      end

      def parsed_oauth_token
        Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)
      end

      # Check if the request is GET/HEAD, or if CSRF token is valid.
      def verified_request?
        Gitlab::RequestForgeryProtection.verified?(current_request.env)
      end

      def ensure_action_dispatch_request(request)
        ActionDispatch::Request.new(request.env.dup)
      end

      def current_request
        @current_request ||= ensure_action_dispatch_request(request)
      end

      def valid_web_access_format?(request_format)
        case request_format
        when :rss
          rss_request?
        when :ics
          ics_request?
        when :api
          api_request?
        when :archive
          archive_request?
        when :download
          download_request?
        end
      end

      def valid_rss_format?(request_format)
        case request_format
        when :rss
          rss_request?
        when :ics
          ics_request?
        end
      end

      def valid_static_objects_format?(request_format)
        case request_format
        when :archive
          archive_request?
        when :blob
          blob_request?
        else
          false
        end
      end

      def rss_request?
        current_request.path.ends_with?('.atom') || current_request.format.atom?
      end

      def ics_request?
        current_request.path.ends_with?('.ics') || current_request.format.ics?
      end

      def api_request?
        current_request.path.starts_with?(Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, '/api/'))
      end

      def git_request?
        Gitlab::PathRegex.repository_git_route_regex.match?(current_request.path)
      end

      def git_lfs_request?
        Gitlab::PathRegex.repository_git_lfs_route_regex.match?(current_request.path)
      end

      def git_or_lfs_request?
        git_request? || git_lfs_request?
      end

      def archive_request?
        current_request.path.include?('/-/archive/')
      end

      def download_request?
        current_request.path.include?('/downloads/')
      end

      def blob_request?
        current_request.path.include?('/raw/')
      end

      def find_valid_running_job_by_token!(token)
        ::Ci::AuthJobFinder.new(token: token).execute.tap do |job|
          raise UnauthorizedError unless job
        end
      end

      def revoke_token_family(token)
        return unless access_token_rotation_request?

        PersonalAccessTokens::RevokeTokenFamilyService.new(token).execute
      end

      def access_token_rotation_request?
        current_request.path.match(%r{access_tokens/(\d+|self)/rotate$})
      end

      # To prevent Rack Attack from incorrectly rate limiting
      # authenticated Git activity, we need to authenticate the user
      # from other means (e.g. HTTP Basic Authentication) only if the
      # request originated from a Git or Git LFS
      # request. Repositories::GitHttpClientController or
      # Repositories::LfsApiController normally does the authentication,
      # but Rack Attack runs before those controllers.
      def find_user_for_git_or_lfs_request
        return unless git_or_lfs_request?

        find_user_from_lfs_token || find_user_from_basic_auth_password
      end

      def find_user_from_personal_access_token_for_api_or_git
        return unless api_request? || git_or_lfs_request?

        find_user_from_personal_access_token
      end

      def find_user_from_dependency_proxy_token
        return unless dependency_proxy_request?

        token, _ = ActionController::HttpAuthentication::Token.token_and_options(current_request)

        return unless token

        user_or_deploy_token = ::DependencyProxy::AuthTokenService.user_or_deploy_token_from_jwt(token)

        # Do not return deploy tokens
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/342481
        return unless user_or_deploy_token.is_a?(::User)

        user_or_deploy_token
      rescue ActiveRecord::RecordNotFound
        nil # invalid id used return no user
      end

      def dependency_proxy_request?
        Gitlab::PathRegex.dependency_proxy_route_regex.match?(current_request.path)
      end
    end
  end
end

Gitlab::Auth::AuthFinders.prepend_mod_with('Gitlab::Auth::AuthFinders')
