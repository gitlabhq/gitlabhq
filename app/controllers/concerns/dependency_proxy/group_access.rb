# frozen_string_literal: true

module DependencyProxy
  module GroupAccess
    extend ActiveSupport::Concern

    included do
      before_action :verify_dependency_proxy_available!
      before_action :authorize_read_dependency_proxy!
    end

    private

    def verify_dependency_proxy_available!
      render_404 unless group&.dependency_proxy_feature_available?
    end

    def authorize_read_dependency_proxy!
      access_denied! unless can?(auth_user, :read_dependency_proxy, group)
    end
  end
end

DependencyProxy::GroupAccess.prepend_mod_with('DependencyProxy::GroupAccess')
