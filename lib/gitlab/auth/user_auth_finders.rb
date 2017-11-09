module Gitlab
  module Auth
    module UserAuthFinders
      PRIVATE_TOKEN_HEADER = 'HTTP_PRIVATE_TOKEN'.freeze
      PRIVATE_TOKEN_PARAM = :private_token

      # Check the Rails session for valid authentication details
      def find_user_from_warden
        current_request.env['warden']&.authenticate if verified_request?
      end

      def find_user_from_rss_token
        return unless current_request.format.atom?

        token = current_request.params[:rss_token].presence
        return unless token

        handle_return_value!(User.find_by_rss_token(token))
      end

      def find_user_from_access_token
        return unless access_token

        validate_access_token!

        handle_return_value!(access_token.user)
      end

      def validate_access_token!(scopes: [])
        return unless access_token

        case AccessTokenValidationService.new(access_token, request: request).validate(scopes: scopes)
        when AccessTokenValidationService::INSUFFICIENT_SCOPE
          raise API::APIGuard::InsufficientScopeError.new(scopes)
        when AccessTokenValidationService::EXPIRED
          raise API::APIGuard::ExpiredError
        when AccessTokenValidationService::REVOKED
          raise API::APIGuard::RevokedError
        end
      end

      private

      def handle_return_value!(value, &block)
        raise API::APIGuard::UnauthorizedError unless value

        block_given? ? yield(value) : value
      end

      def access_token
        return @access_token if defined?(@access_token)

        @access_token = find_oauth_access_token || find_personal_access_token
      end

      def private_token
        current_request.params[PRIVATE_TOKEN_PARAM].presence ||
          current_request.env[PRIVATE_TOKEN_HEADER].presence
      end

      def find_personal_access_token
        token = private_token
        return unless token

        # Expiration, revocation and scopes are verified in `validate_access_token!`
        handle_return_value!(PersonalAccessToken.find_by(token: token))
      end

      def find_oauth_access_token
        token = Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)
        return unless token

        # Expiration, revocation and scopes are verified in `validate_access_token!`
        handle_return_value!(OauthAccessToken.by_token(token)) do |oauth_token|
          oauth_token.revoke_previous_refresh_token!
          oauth_token
        end
      end

      # Check if the request is GET/HEAD, or if CSRF token is valid.
      def verified_request?
        Gitlab::RequestForgeryProtection.verified?(current_request.env)
      end

      def ensure_action_dispatch_request(request)
        return request if request.is_a?(ActionDispatch::Request)

        ActionDispatch::Request.new(request.env)
      end

      def current_request
        @current_request ||= ensure_action_dispatch_request(request)
      end
    end
  end
end
