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

      def authenticate_user_from_jwt_token!
        authenticate_with_http_token do |token, _|
          @authentication_result = EMPTY_AUTH_RESULT

          user_or_deploy_token = ::DependencyProxy::AuthTokenService.user_or_deploy_token_from_jwt(token)

          case user_or_deploy_token
          when User
            @authentication_result = Gitlab::Auth::Result.new(user_or_deploy_token, nil, :user, [])
            sign_in(user_or_deploy_token) unless user_or_deploy_token.project_bot? ||
              user_or_deploy_token.service_account?
          when DeployToken
            @authentication_result = Gitlab::Auth::Result.new(user_or_deploy_token, nil, :deploy_token, [])
          end
        end

        request_bearer_token! unless authenticated_user
      end

      private

      def request_bearer_token!
        # unfortunately, we cannot use https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token.html#method-i-authentication_request
        response.headers['WWW-Authenticate'] = ::DependencyProxy::Registry.authenticate_header
        render plain: '', status: :unauthorized
      end
    end
  end
end
