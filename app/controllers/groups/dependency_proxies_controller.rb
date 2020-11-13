# frozen_string_literal: true

module Groups
  class DependencyProxiesController < Groups::ApplicationController
    include DependencyProxyAccess

    before_action :authorize_admin_dependency_proxy!, only: :update
    before_action :dependency_proxy

    feature_category :package_registry

    def show
      @blobs_count = group.dependency_proxy_blobs.count
      @blobs_total_size = group.dependency_proxy_blobs.total_size
    end

    def update
      dependency_proxy.update(dependency_proxy_params)

      redirect_to group_dependency_proxy_path(group)
    end

    private

    def dependency_proxy
      @dependency_proxy ||=
        group.dependency_proxy_setting || group.create_dependency_proxy_setting
    end

    def dependency_proxy_params
      params.require(:dependency_proxy_group_setting).permit(:enabled)
    end
  end
end
