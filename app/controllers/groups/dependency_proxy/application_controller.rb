# frozen_string_literal: true

module Groups
  module DependencyProxy
    class ApplicationController < ::ApplicationController
      EMPTY_AUTH_RESULT = Gitlab::Auth::Result.new(nil, nil, nil, nil).freeze

      delegate :actor, to: :@authentication_result, allow_nil: true

      # This allows auth_user to be set in the base ApplicationController
      alias_method :authenticated_user, :actor

      # We disable `authenticate_user!` since the `DependencyProxy::ApplicationController` performs auth using JWT token
      skip_before_action :authenticate_user!, raise: false

      prepend_before_action :authenticate_user_from_jwt_token!
      before_action :skip_session

      def authenticate_user_from_jwt_token!
        authenticate_with_http_token do |token, _|
          @authentication_result = EMPTY_AUTH_RESULT

          user_or_token = ::DependencyProxy::AuthTokenService.user_or_token_from_jwt(token)

          case user_or_token
          when User
            set_auth_result(user_or_token, :user)
            sign_in(user_or_token) if can_sign_in?(user_or_token)
          when PersonalAccessToken
            set_auth_result(user_or_token.user, :personal_access_token)
            @personal_access_token = user_or_token
          when DeployToken
            set_auth_result(user_or_token, :deploy_token)
          end
        end

        request_bearer_token! unless authenticated_user
      end

      private

      attr_reader :personal_access_token

      def request_bearer_token!
        # unfortunately, we cannot use https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token.html#method-i-authentication_request
        response.headers['WWW-Authenticate'] = ::DependencyProxy::Registry.authenticate_header
        render plain: '', status: :unauthorized
      end

      def can_sign_in?(user_or_token)
        return false if user_or_token.project_bot? || user_or_token.service_account?

        true
      end

      def set_auth_result(actor, type)
        @authentication_result = Gitlab::Auth::Result.new(actor, nil, type, [])
      end

      def skip_session
        request.session_options[:skip] = true
      end
    end
  end
end
