# frozen_string_literal: true

module Groups
  class DependencyProxiesController < Groups::ApplicationController
    include ::DependencyProxy::GroupAccess

    before_action :verify_dependency_proxy_enabled!

    feature_category :virtual_registry
    urgency :low

    private

    def dependency_proxy
      @dependency_proxy ||=
        group.dependency_proxy_setting || group.create_dependency_proxy_setting!
    end

    def verify_dependency_proxy_enabled!
      render_404 unless dependency_proxy.enabled?
    end
  end
end
