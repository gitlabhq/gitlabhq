module Projects
  module Registry
    class RepositoriesController < ::Projects::Registry::ApplicationController
      before_action :authorize_update_container_image!, only: [:destroy]
      before_action :ensure_root_container_repository!, only: [:index]

      def index
        @images = project.container_repositories
      end

      def destroy
        if image.destroy
          redirect_to project_container_registry_index_path(@project),
                      status: 302,
                      notice: 'Image repository has been removed successfully!'
        else
          redirect_to project_container_registry_index_path(@project),
                      status: 302,
                      alert: 'Failed to remove image repository!'
        end
      end

      private

      def image
        @image ||= project.container_repositories.find(params[:id])
      end

      ##
      # Container repository object for root project path.
      #
      # Needed to maintain a backwards compatibility.
      #
      def ensure_root_container_repository!
        ContainerRegistry::Path.new(@project.full_path).tap do |path|
          break if path.has_repository?

          ContainerRepository.build_from_path(path).tap do |repository|
            repository.save! if repository.has_tags?
          end
        end
      end
    end
  end
end
