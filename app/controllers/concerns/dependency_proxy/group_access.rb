# frozen_string_literal: true

module DependencyProxy
  module GroupAccess
    extend ActiveSupport::Concern

    included do
      before_action :verify_dependency_proxy_available!
      before_action :authorize_read_dependency_proxy!
    end

    private

    def auth_user_or_token
      if defined?(personal_access_token) && personal_access_token && auth_user.is_a?(::User) &&
          (
            (auth_user.project_bot? && auth_user.resource_bot_resource.is_a?(::Group)) ||
            auth_user.human? ||
            auth_user.service_account?
          )
        personal_access_token
      else
        auth_user
      end
    end

    def verify_dependency_proxy_available!
      render_404 unless group&.dependency_proxy_feature_available?
    end

    # TODO: Split the authorization logic into dedicated methods
    # https://gitlab.com/gitlab-org/gitlab/-/issues/452145
    def authorize_read_dependency_proxy!
      if auth_user_or_token.is_a?(User)
        authorize_read_dependency_proxy_for_users!
      else
        authorize_read_dependency_proxy_for_tokens!
      end
    end

    def authorize_read_dependency_proxy_for_users!
      access_denied! unless can?(auth_user, :read_dependency_proxy, group)
    end

    def authorize_read_dependency_proxy_for_tokens!
      access_denied! unless can?(auth_user_or_token, :read_dependency_proxy,
        group&.dependency_proxy_for_containers_policy_subject)
    end
  end
end

DependencyProxy::GroupAccess.prepend_mod_with('DependencyProxy::GroupAccess')
