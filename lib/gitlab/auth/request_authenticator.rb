# Use for authentication only, in particular for Rack::Attack.
# Does not perform authorization of scopes, etc.
module Gitlab
  module Auth
    class RequestAuthenticator
      include UserAuthFinders

      attr_reader :request

      def initialize(request)
        @request = ensure_action_dispatch_request(request)
      end

      def user
        find_sessionless_user || find_session_user
      end

      def find_sessionless_user
        find_user_by_private_token || find_user_by_rss_token || find_user_by_oauth_token
      end
    end
  end
end
