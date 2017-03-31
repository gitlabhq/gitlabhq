module Projects
  module Registry
    class RepositoriesController < ::Projects::Registry::ApplicationController
      before_action :authorize_update_container_image!, only: [:destroy]

      def index
        @images = project.container_repositories
      end

      def destroy
        if image.destroy
          redirect_to project_container_registry_path(@project)
        else
          redirect_to project_container_registry_path(@project),
                      alert: 'Failed to remove images repository!'
        end
      end

      private

      def image
        @image ||= project.container_repositories.find_by(id: params[:id])
      end
    end
  end
end
