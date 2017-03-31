module Projects
  module Registry
    class RepositoriesController < ::Projects::Registry::ApplicationController
      before_action :authorize_update_container_image!, only: [:destroy]

      def index
        @images = project.container_repositories
      end

      def destroy
        if tag
          delete_tag
        else
          delete_image
        end
      end

      private

      def registry_url
        @registry_url ||= namespace_project_container_registry_index_path(project.namespace, project)
      end

      def verify_registry_enabled
        render_404 unless Gitlab.config.registry.enabled
      end

      def delete_image
        if image.destroy
          redirect_to registry_url
        else
          redirect_to registry_url, alert: 'Failed to remove image'
        end
      end

      def delete_tag
        if tag.delete
          image.destroy if image.tags.empty?
          redirect_to registry_url
        else
          redirect_to registry_url, alert: 'Failed to remove tag'
        end
      end

      def image
        @image ||= project.container_repositories.find_by(id: params[:id])
      end

      def tag
        @tag ||= image.tag(params[:tag]) if params[:tag].present?
      end
    end
  end
end
