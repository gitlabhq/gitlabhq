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

    module UserAuthFinders
      prepend_if_ee('::EE::Gitlab::Auth::UserAuthFinders') # rubocop: disable Cop/InjectEnterpriseEditionModule

      include Gitlab::Utils::StrongMemoize

      PRIVATE_TOKEN_HEADER = 'HTTP_PRIVATE_TOKEN'
      PRIVATE_TOKEN_PARAM = :private_token

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

        # NOTE: feed_token was renamed from rss_token but both needs to be supported because
        #       users might have already added the feed to their RSS reader before the rename
        token = current_request.params[:feed_token].presence || current_request.params[:rss_token].presence
        return unless token

        User.find_by_feed_token(token) || raise(UnauthorizedError)
      end

      # We only allow Private Access Tokens with `api` scope to be used by web
      # requests on RSS feeds or ICS files for backwards compatibility.
      # It is also used by GraphQL/API requests.
      def find_user_from_web_access_token(request_format)
        return unless access_token && valid_web_access_format?(request_format)

        validate_access_token!(scopes: [:api])

        access_token.user || raise(UnauthorizedError)
      end

      def find_user_from_access_token
        return unless access_token

        validate_access_token!

        access_token.user || raise(UnauthorizedError)
      end

      def validate_access_token!(scopes: [])
        return unless access_token

        case AccessTokenValidationService.new(access_token, request: request).validate(scopes: scopes)
        when AccessTokenValidationService::INSUFFICIENT_SCOPE
          raise InsufficientScopeError.new(scopes)
        when AccessTokenValidationService::EXPIRED
          raise ExpiredError
        when AccessTokenValidationService::REVOKED
          raise RevokedError
        when AccessTokenValidationService::IMPERSONATION_DISABLED
          raise ImpersonationDisabled
        end
      end

      private

      def route_authentication_setting
        return {} unless respond_to?(:route_setting)

        route_setting(:authentication) || {}
      end

      def access_token
        strong_memoize(:access_token) do
          find_oauth_access_token || find_personal_access_token
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

      def parsed_oauth_token
        Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)
      end

      def matches_personal_access_token_length?(token)
        token.length == PersonalAccessToken::TOKEN_LENGTH
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
        current_request.path.starts_with?("/api/")
      end

      def archive_request?
        current_request.path.include?('/-/archive/')
      end

      def blob_request?
        current_request.path.include?('/raw/')
      end
    end
  end
end
