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
        find_user_from_web_access_token(request_format, scopes: [:api, :read_api]) ||
          find_user_from_feed_token(request_format) ||
          find_user_from_static_object_token(request_format) ||
          find_user_from_basic_auth_job ||
          find_user_from_job_token ||
          find_user_from_lfs_token ||
          find_user_from_personal_access_token ||
          find_user_from_basic_auth_password
      rescue Gitlab::Auth::AuthenticationError
        nil
      end

      def valid_access_token?(scopes: [])
        validate_access_token!(scopes: scopes)

        true
      rescue Gitlab::Auth::AuthenticationError
        false
      end

      private

      def access_token
        strong_memoize(:access_token) do
          super || find_personal_access_token_from_http_basic_auth
        end
      end

      def route_authentication_setting
        @route_authentication_setting ||= {
          job_token_allowed: api_request?,
          basic_auth_personal_access_token: api_request? || git_request?
        }
      end
    end
  end
end
