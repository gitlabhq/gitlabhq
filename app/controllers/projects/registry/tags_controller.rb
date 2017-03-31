module Projects
  module Registry
    class TagsController < ::Projects::Registry::ApplicationController
      before_action :authorize_update_container_image!, only: [:destroy]

      def destroy
        if tag.delete
          redirect_to project_container_registry_path(@project),
                      notice: 'Tag removed successfull!'
        else
          redirect_to project_container_registry_path(@project),
                      alert: 'Failed to remove repository tag!'
        end
      end

      private

      def repository
        @image ||= project.container_repositories
          .find_by(id: params[:repository_id])
      end

      def tag
        @tag ||= repository.tag(params[:id]) if params[:id].present?
      end
    end
  end
end
