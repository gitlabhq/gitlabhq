# frozen_string_literal: true
module Groups
  module Registry
    class RepositoriesController < Groups::ApplicationController
      before_action :verify_container_registry_enabled!
      before_action :authorize_read_container_image!
      before_action :feature_flag_group_container_registry_browser!

      def index
        respond_to do |format|
          format.html
          format.json do
            @images = group.container_repositories.with_api_entity_associations

            track_event(:list_repositories)

            serializer = ContainerRepositoriesSerializer
              .new(current_user: current_user)

            if Feature.enabled?(:vue_container_registry_explorer)
              render json: serializer.with_pagination(request, response)
                .represent_read_only(@images)
            else
              render json: serializer.represent_read_only(@images)
            end
          end
        end
      end

      # The show action renders index to allow frontend routing to work on page refresh
      def show
        render :index
      end

      private

      def feature_flag_group_container_registry_browser!
        render_404 unless Feature.enabled?(:group_container_registry_browser, group)
      end

      def verify_container_registry_enabled!
        render_404 unless Gitlab.config.registry.enabled
      end

      def authorize_read_container_image!
        return render_404 unless can?(current_user, :read_container_image, group)
      end
    end
  end
end
