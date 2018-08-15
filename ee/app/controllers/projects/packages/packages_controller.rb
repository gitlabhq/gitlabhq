module Projects
  module Packages
    class PackagesController < ApplicationController
      before_action :verify_packages_enabled!
      before_action :authorize_read_package!
      before_action :authorize_admin_package!, only: [:destroy]

      def index
        @packages = project.packages.all.page(params[:page])
      end

      def show
        @package = project.packages.find(params[:id])
        @package_files = @package.package_files.recent
        @maven_metadatum = @package.maven_metadatum
      end

      def destroy
        @package = project.packages.find(params[:id])
        @package.destroy

        redirect_to project_packages_path(@project), status: 302, notice: _('Package was removed')
      end

      private

      def verify_packages_enabled!
        render_404 unless Gitlab.config.packages.enabled
      end
    end
  end
end
