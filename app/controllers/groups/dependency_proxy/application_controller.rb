# frozen_string_literal: true

module Groups
  module DependencyProxy
    class ApplicationController < ::ApplicationController
      include Gitlab::Utils::StrongMemoize

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

          if Feature.enabled?(:packages_dependency_proxy_pass_token_to_policy, group)
            user_or_token = ::DependencyProxy::AuthTokenService.user_or_token_from_jwt(token)
            sign_in_and_setup_authentication_result(user_or_token)
          else
            user_or_token = ::DependencyProxy::AuthTokenService.user_or_deploy_token_from_jwt(token)
            case user_or_token
            when User
              @authentication_result = Gitlab::Auth::Result.new(user_or_token, nil, :user, [])
              sign_in(user_or_token) unless user_or_token.project_bot? || user_or_token.service_account?
            when DeployToken
              @authentication_result = Gitlab::Auth::Result.new(user_or_token, nil, :deploy_token, [])
            end
          end
        end

        request_bearer_token! unless authenticated_user
      end

      private

      attr_reader :personal_access_token

      # TODO: We only need this here to get the group for the Feature flag evaluation.
      # Move this back to app/controllers/groups/dependency_proxy_for_containers_controller.rb
      # when we rollout the FF packages_dependency_proxy_pass_token_to_policy
      def group
        Group.find_by_full_path(params[:group_id], follow_redirects: true)
      end
      strong_memoize_attr :group

      def request_bearer_token!
        # unfortunately, we cannot use https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token.html#method-i-authentication_request
        response.headers['WWW-Authenticate'] = ::DependencyProxy::Registry.authenticate_header
        render plain: '', status: :unauthorized
      end

      # When we rollout packages_dependency_proxy_pass_token_to_policy,
      # we can move the body of this method inline, inside authenticate_user_from_jwt_token!
      def sign_in_and_setup_authentication_result(user_or_token)
        case user_or_token
        when User
          @authentication_result = Gitlab::Auth::Result.new(user_or_token, nil, :user, [])
          sign_in(user_or_token) if can_sign_in?(user_or_token)
        when PersonalAccessToken
          @authentication_result = Gitlab::Auth::Result.new(user_or_token.user, nil, :personal_access_token, [])
          @personal_access_token = user_or_token
        when DeployToken
          @authentication_result = Gitlab::Auth::Result.new(user_or_token, nil, :deploy_token, [])
        end
      end

      def can_sign_in?(user_or_token)
        return false if user_or_token.project_bot? || user_or_token.service_account?

        true
      end
    end
  end
end
