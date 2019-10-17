# frozen_string_literal: true
module Groups
  module Registry
    class RepositoriesController < Groups::ApplicationController
      before_action :verify_container_registry_enabled!
      before_action :authorize_read_container_image!

      def index
        track_event(:list_repositories)

        respond_to do |format|
          format.html
          format.json do
            @images = group.container_repositories.with_api_entity_associations

            render json: ContainerRepositoriesSerializer
              .new(current_user: current_user)
              .represent(@images)
          end
        end
      end

      private

      def verify_container_registry_enabled!
        render_404 unless Gitlab.config.registry.enabled
      end

      def authorize_read_container_image!
        return render_404 unless can?(current_user, :read_container_image, group)
      end
    end
  end
end
