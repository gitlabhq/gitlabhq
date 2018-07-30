module Projects
  module Packages
    class PackagesController < ApplicationController
      before_action :authorize_admin_project!

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

        redirect_to project_packages_path(@project), notice: _('Package was removed')
      end
    end
  end
end
