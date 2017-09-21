module Projects
  module Registry
    class RepositoriesController < ::Projects::Registry::ApplicationController
      before_action :authorize_update_container_image!, only: [:destroy]
      before_action :ensure_root_container_repository!, only: [:index]

      def index
        @images = project.container_repositories

        respond_to do |format|
          format.html
          format.json do
            render json: ContainerRepositoriesSerializer
              .new(project: project, current_user: current_user)
              .represent(@images)
          end
        end
      end

      def destroy
        if image.destroy
          respond_to do |format|
            format.json { head :no_content }
          end
        else
          respond_to do |format|
            format.json { head :bad_request }
          end
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
