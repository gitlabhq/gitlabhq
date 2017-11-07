module Gitlab
  module Auth
    module UserAuthFinders
      # Check the Rails session for valid authentication details
      def find_session_user
        request.env['warden']&.authenticate if verified_request?
      end

      def find_user_by_private_token
        token = private_token
        return unless token.present?

        user =
          find_user_by_authentication_token(token) ||
          find_user_by_personal_access_token(token)

        raise_unauthorized_error! unless user

        user
      end

      def private_token
        request.params[:private_token].presence ||
          request.headers['PRIVATE-TOKEN'].presence
      end

      def find_user_by_authentication_token(token_string)
        User.find_by_authentication_token(token_string)
      end

      def find_user_by_personal_access_token(token_string)
        access_token = PersonalAccessToken.find_by_token(token_string)
        return unless access_token

        find_user_by_access_token(access_token)
      end

      def find_user_by_rss_token
        return unless request.path.ends_with?('atom') || request.format.atom?

        token = request.params[:rss_token].presence
        return unless token.present?

        user = User.find_by_rss_token(token)
        raise_unauthorized_error! unless user

        user
      end

      def find_user_by_oauth_token
        access_token = find_oauth_access_token

        return unless access_token

        find_user_by_access_token(access_token)
      end

      def find_oauth_access_token
        return @oauth_access_token if defined?(@oauth_access_token)

        current_request = ensure_action_dispatch_request(request)
        token = Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)
        return @oauth_access_token = nil unless token

        @oauth_access_token = OauthAccessToken.by_token(token)
        raise_unauthorized_error! unless @oauth_access_token

        @oauth_access_token.revoke_previous_refresh_token!
        @oauth_access_token
      end

      def find_user_by_access_token(access_token)
        access_token&.user
      end

      # Check if the request is GET/HEAD, or if CSRF token is valid.
      def verified_request?
        Gitlab::RequestForgeryProtection.verified?(request.env)
      end

      def ensure_action_dispatch_request(request)
        return request if request.is_a?(ActionDispatch::Request)

        ActionDispatch::Request.new(request.env)
      end

      def raise_unauthorized_error!
        return nil
      end
    end
  end
end
