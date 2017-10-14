# Use for authentication only, in particular for Rack::Attack.
# Does not perform authorization of scopes, etc.
module Gitlab
  module Auth
    class RequestAuthenticator
      def initialize(request)
        @request = request
      end

      def user
        find_sessionless_user || find_session_user
      end

      def find_sessionless_user
        find_user_by_private_token || find_user_by_rss_token || find_user_by_oauth_token
      end

      private

      def find_session_user
        @request.env['warden']&.authenticate if verified_request?
      end

      # request may be Rack::Attack::Request which is just a Rack::Request, so
      # we cannot use ActionDispatch::Request methods.
      def find_user_by_private_token
        token = @request.params['private_token'].presence || @request.env['HTTP_PRIVATE_TOKEN'].presence
        return unless token.present?

        User.find_by_authentication_token(token) || User.find_by_personal_access_token(token)
      end

      # request may be Rack::Attack::Request which is just a Rack::Request, so
      # we cannot use ActionDispatch::Request methods.
      def find_user_by_rss_token
        return unless @request.path.ends_with?('atom') || @request.env['HTTP_ACCEPT'] == 'application/atom+xml'

        token = @request.params['rss_token'].presence
        return unless token.present?

        User.find_by_rss_token(token)
      end

      def find_user_by_oauth_token
        access_token = find_oauth_access_token
        access_token&.user
      end

      def find_oauth_access_token
        token = Doorkeeper::OAuth::Token.from_request(doorkeeper_request, *Doorkeeper.configuration.access_token_methods)
        OauthAccessToken.by_token(token) if token
      end

      def doorkeeper_request
        ActionDispatch::Request.new(@request.env)
      end

      # Check if the request is GET/HEAD, or if CSRF token is valid.
      def verified_request?
        Gitlab::RequestForgeryProtection.verified?(@request.env)
      end
    end
  end
end
