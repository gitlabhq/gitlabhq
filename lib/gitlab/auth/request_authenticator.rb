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

      def find_authenticated_requester(request_formats)
        user(request_formats) || deploy_token_from_request
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
        case request_format
        when :graphql_api
          find_user_for_graphql_api_request
        when :api, :git, :rss, :ics, :blob, :download, :archive, nil
          find_user_from_any_authentication_method(request_format)
        else
          raise ArgumentError, "Unknown request format"
        end
      rescue Gitlab::Auth::AuthenticationError
        nil
      end

      def can_sign_in_bot?(user)
        (user&.project_bot? || user&.service_account?) && api_request?
      end

      def valid_access_token?(scopes: [])
        # We may just be checking whether the user has :admin_mode access, so
        # don't construe an auth failure as a real failure.
        validate_and_save_access_token!(scopes: scopes, save_auth_context: false)

        true
      rescue Gitlab::Auth::AuthenticationError
        false
      end

      private

      # Use a minimal subset of find_user_from_any_authentication_method
      # so only token types allowed for GraphQL can authenticate users.
      # CI_JOB_TOKENs are not allowed for now, since their access is too broad.
      #
      # Overridden in EE
      def find_user_for_graphql_api_request
        find_user_from_web_access_token(:api, scopes: graphql_authorization_scopes) ||
          find_user_from_personal_access_token_for_api_or_git
      end

      # Overridden in EE
      def graphql_authorization_scopes
        [:api, :read_api]
      end

      def find_user_from_any_authentication_method(request_format)
        find_user_from_dependency_proxy_token ||
          find_user_from_web_access_token(request_format, scopes: [:api, :read_api]) ||
          find_user_from_feed_token(request_format) ||
          find_user_from_static_object_token(request_format) ||
          find_user_from_job_token ||
          find_user_from_personal_access_token_for_api_or_git ||
          find_user_for_git_or_lfs_request
      end

      def access_token
        strong_memoize(:access_token) do
          super || find_personal_access_token_from_http_basic_auth
        end
      end

      def route_authentication_setting
        @route_authentication_setting ||= {
          job_token_allowed: api_request?,
          basic_auth_personal_access_token: api_request? || git_request?,
          deploy_token_allowed: api_request? || git_request?
        }
      end
    end
  end
end

Gitlab::Auth::RequestAuthenticator.prepend_mod
