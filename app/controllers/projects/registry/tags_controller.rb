module Projects
  module Registry
    class TagsController < ::Projects::Registry::ApplicationController
      before_action :authorize_update_container_image!, only: [:destroy]

      def destroy
        if tag.delete
          redirect_to project_container_registry_index_path(@project),
                      status: 302,
                      notice: 'Registry tag has been removed successfully!'
        else
          redirect_to project_container_registry_index_path(@project),
                      status: 302,
                      alert: 'Failed to remove registry tag!'
        end
      end

      private

      def image
        @image ||= project.container_repositories
          .find(params[:repository_id])
      end

      def tag
        @tag ||= image.tag(params[:id])
      end
    end
  end
end
