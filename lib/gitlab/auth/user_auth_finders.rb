module Gitlab
  module Auth
    #
    # Exceptions
    #

    AuthenticationError = Class.new(StandardError)
    MissingTokenError = Class.new(AuthenticationError)
    TokenNotFoundError = Class.new(AuthenticationError)
    ExpiredError = Class.new(AuthenticationError)
    RevokedError = Class.new(AuthenticationError)
    UnauthorizedError = Class.new(AuthenticationError)

    class InsufficientScopeError < AuthenticationError
      attr_reader :scopes
      def initialize(scopes)
        @scopes = scopes.map { |s| s.try(:name) || s }
      end
    end

    module UserAuthFinders
      include Gitlab::Utils::StrongMemoize

      PRIVATE_TOKEN_HEADER = 'HTTP_PRIVATE_TOKEN'.freeze
      PRIVATE_TOKEN_PARAM = :private_token

      # Check the Rails session for valid authentication details
      def find_user_from_warden
        current_request.env['warden']&.authenticate if verified_request?
      end

      def find_user_from_rss_token
        return unless current_request.path.ends_with?('.atom') || current_request.format.atom?

        token = current_request.params[:rss_token].presence
        return unless token

        User.find_by_rss_token(token) || raise(UnauthorizedError)
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
        end
      end

      private

      def access_token
        strong_memoize(:access_token) do
          find_oauth_access_token || find_personal_access_token
        end
      end

      def find_personal_access_token
        token =
          current_request.params[PRIVATE_TOKEN_PARAM].presence ||
          current_request.env[PRIVATE_TOKEN_HEADER].presence

        return unless token

        # Expiration, revocation and scopes are verified in `validate_access_token!`
        PersonalAccessToken.find_by(token: token) || raise(UnauthorizedError)
      end

      def find_oauth_access_token
        token = Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)
        return unless token

        # Expiration, revocation and scopes are verified in `validate_access_token!`
        oauth_token = OauthAccessToken.by_token(token)
        raise UnauthorizedError unless oauth_token

        oauth_token.revoke_previous_refresh_token!
        oauth_token
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
    end
  end
end
