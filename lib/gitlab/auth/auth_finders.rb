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

      # Check the Rails session for valid authentication details
      def find_user_from_warden
        current_request.env['warden']&.authenticate if verified_request?
      end

      def find_user_from_static_object_token(request_format)
        return unless valid_static_objects_format?(request_format)

        token = current_request.params[:token].presence || current_request.headers['X-Gitlab-Static-Object-Token'].presence
        return unless token

        User.find_by_static_object_token(token) || raise(UnauthorizedError)
      end

      def find_user_from_feed_token(request_format)
        return unless valid_rss_format?(request_format)
        return if Gitlab::CurrentSettings.disable_feed_token

        # NOTE: feed_token was renamed from rss_token but both needs to be supported because
        #       users might have already added the feed to their RSS reader before the rename
        token = current_request.params[:feed_token].presence || current_request.params[:rss_token].presence
        return unless token

        User.find_by_feed_token(token) || raise(UnauthorizedError)
      end

      def find_user_from_bearer_token
        find_user_from_job_bearer_token ||
          find_user_from_access_token
      end

      def find_user_from_job_token
        return unless route_authentication_setting[:job_token_allowed]
        return find_user_from_basic_auth_job if route_authentication_setting[:job_token_allowed] == :basic_auth

        token = current_request.params[JOB_TOKEN_PARAM].presence ||
          current_request.params[RUNNER_JOB_TOKEN_PARAM].presence ||
          current_request.env[JOB_TOKEN_HEADER].presence
        return unless token

        job = find_valid_running_job_by_token!(token)
        @current_authenticated_job = job # rubocop:disable Gitlab/ModuleWithInstanceVariables

        job.user
      end

      def find_user_from_basic_auth_job
        return unless has_basic_credentials?(current_request)

        login, password = user_name_and_password(current_request)
        return unless login.present? && password.present?
        return unless ::Gitlab::Auth::CI_JOB_USER == login

        job = find_valid_running_job_by_token!(password)
        @current_authenticated_job = job # rubocop:disable Gitlab/ModuleWithInstanceVariables

        job.user
      end

      def find_user_from_basic_auth_password
        return unless has_basic_credentials?(current_request)

        login, password = user_name_and_password(current_request)
        return if ::Gitlab::Auth::CI_JOB_USER == login

        Gitlab::Auth.find_with_user_password(login, password)
      end

      def find_user_from_lfs_token
        return unless has_basic_credentials?(current_request)

        login, token = user_name_and_password(current_request)
        user = User.by_login(login)

        user if user && Gitlab::LfsToken.new(user).token_valid?(token)
      end

      def find_user_from_personal_access_token
        return unless access_token

        validate_access_token!

        access_token&.user || raise(UnauthorizedError)
      end

      # We allow Private Access Tokens with `api` scope to be used by web
      # requests on RSS feeds or ICS files for backwards compatibility.
      # It is also used by GraphQL/API requests.
      # And to allow accessing /archive programatically as it was a big pain point
      # for users https://gitlab.com/gitlab-org/gitlab/-/issues/28978.
      def find_user_from_web_access_token(request_format, scopes: [:api])
        return unless access_token && valid_web_access_format?(request_format)

        validate_access_token!(scopes: scopes)

        ::PersonalAccessTokens::LastUsedService.new(access_token).execute

        access_token.user || raise(UnauthorizedError)
      end

      def find_user_from_access_token
        return unless access_token

        validate_access_token!

        ::PersonalAccessTokens::LastUsedService.new(access_token).execute

        access_token.user || raise(UnauthorizedError)
      end

      # This returns a deploy token, not a user since a deploy token does not
      # belong to a user.
      #
      # deploy tokens are accepted with deploy token headers and basic auth headers
      def deploy_token_from_request
        return unless route_authentication_setting[:deploy_token_allowed]

        token = current_request.env[DEPLOY_TOKEN_HEADER].presence || parsed_oauth_token

        if has_basic_credentials?(current_request)
          _, token = user_name_and_password(current_request)
        end

        deploy_token = DeployToken.active.find_by_token(token)
        @current_authenticated_deploy_token = deploy_token # rubocop:disable Gitlab/ModuleWithInstanceVariables

        deploy_token
      end

      def cluster_agent_token_from_authorization_token
        return unless route_authentication_setting[:cluster_agent_token_allowed]
        return unless current_request.authorization.present?

        authorization_token, _options = token_and_options(current_request)

        ::Clusters::AgentToken.find_by_token(authorization_token)
      end

      def find_runner_from_token
        return unless api_request?

        token = current_request.params[RUNNER_TOKEN_PARAM].presence
        return unless token

        ::Ci::Runner.find_by_token(token) || raise(UnauthorizedError)
      end

      def validate_access_token!(scopes: [])
        # return early if we've already authenticated via a job token
        return if @current_authenticated_job.present? # rubocop:disable Gitlab/ModuleWithInstanceVariables

        # return early if we've already authenticated via a deploy token
        return if @current_authenticated_deploy_token.present? # rubocop:disable Gitlab/ModuleWithInstanceVariables

        return unless access_token

        case AccessTokenValidationService.new(access_token, request: request).validate(scopes: scopes)
        when AccessTokenValidationService::INSUFFICIENT_SCOPE
          raise InsufficientScopeError, scopes
        when AccessTokenValidationService::EXPIRED
          raise ExpiredError
        when AccessTokenValidationService::REVOKED
          raise RevokedError
        when AccessTokenValidationService::IMPERSONATION_DISABLED
          raise ImpersonationDisabled
        end
      end

      private

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
          if try(:namespace_inheritable, :authentication)
            access_token_from_namespace_inheritable
          else
            # The token can be a PAT or an OAuth (doorkeeper) token
            # It is also possible that a PAT is encapsulated in a `Bearer` OAuth token
            # (e.g. NPM client registry auth), this case will be properly handled
            # by find_personal_access_token
            find_oauth_access_token || find_personal_access_token
          end
        end
      end

      def find_personal_access_token
        token =
          current_request.params[PRIVATE_TOKEN_PARAM].presence ||
          current_request.env[PRIVATE_TOKEN_HEADER].presence ||
          parsed_oauth_token
        return unless token

        # Expiration, revocation and scopes are verified in `validate_access_token!`
        PersonalAccessToken.find_by_token(token) || raise(UnauthorizedError)
      end

      def find_oauth_access_token
        token = parsed_oauth_token
        return unless token

        # PATs with OAuth headers are not handled by OauthAccessToken
        return if matches_personal_access_token_length?(token)

        # Expiration, revocation and scopes are verified in `validate_access_token!`
        oauth_token = OauthAccessToken.by_token(token)
        raise UnauthorizedError unless oauth_token

        oauth_token.revoke_previous_refresh_token!
        oauth_token
      end

      def find_personal_access_token_from_http_basic_auth
        return unless route_authentication_setting[:basic_auth_personal_access_token]
        return unless has_basic_credentials?(current_request)

        _username, password = user_name_and_password(current_request)
        PersonalAccessToken.find_by_token(password)
      end

      def parsed_oauth_token
        Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)
      end

      def matches_personal_access_token_length?(token)
        PersonalAccessToken::TOKEN_LENGTH_RANGE.include?(token.length)
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
          archive_request? if Feature.enabled?(:allow_archive_as_web_access_format, default_enabled: :yaml)
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

      def archive_request?
        current_request.path.include?('/-/archive/')
      end

      def blob_request?
        current_request.path.include?('/raw/')
      end

      def find_valid_running_job_by_token!(token)
        ::Ci::AuthJobFinder.new(token: token).execute.tap do |job|
          raise UnauthorizedError unless job
        end
      end
    end
  end
end

Gitlab::Auth::AuthFinders.prepend_mod_with('Gitlab::Auth::AuthFinders')
