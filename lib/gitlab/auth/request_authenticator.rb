# frozen_string_literal: true

# Use for authentication only, in particular for Rack::Attack.
# Does not perform authorization of scopes, etc.
module Gitlab
  module Auth
    class RequestAuthenticator
      include AuthFinders

      attr_reader :request

      def initialize(request)
        @request = request
      end

      def user(request_formats)
        request_formats.each do |format|
          user = find_sessionless_user(format)

          return user if user
        end

        find_user_from_warden
      end

      def runner
        find_runner_from_token
      rescue Gitlab::Auth::AuthenticationError
        nil
      end

      def find_sessionless_user(request_format)
        find_user_from_web_access_token(request_format) ||
          find_user_from_feed_token(request_format) ||
          find_user_from_static_object_token(request_format)
      rescue Gitlab::Auth::AuthenticationError
        nil
      end

      def valid_access_token?(scopes: [])
        validate_access_token!(scopes: scopes)

        true
      rescue Gitlab::Auth::AuthenticationError
        false
      end
    end
  end
end
