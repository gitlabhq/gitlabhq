# frozen_string_literal: true

module DependencyProxyAccess
  extend ActiveSupport::Concern

  included do
    before_action :verify_dependency_proxy_enabled!
    before_action :authorize_read_dependency_proxy!
  end

  private

  def verify_dependency_proxy_enabled!
    render_404 unless group.dependency_proxy_feature_available?
  end

  def authorize_read_dependency_proxy!
    access_denied! unless can?(current_user, :read_dependency_proxy, group)
  end

  def authorize_admin_dependency_proxy!
    access_denied! unless can?(current_user, :admin_dependency_proxy, group)
  end
end
