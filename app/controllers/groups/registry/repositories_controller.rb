# frozen_string_literal: true
module Groups
  module Registry
    class RepositoriesController < Groups::ApplicationController
      include PackagesHelper
      include ::Registry::ConnectionErrorsHandler

      before_action :verify_container_registry_enabled!
      before_action :authorize_read_container_image!

      before_action only: [:index, :show] do
        push_frontend_feature_flag(:show_container_registry_tag_signatures, group)
      end

      feature_category :container_registry
      urgency :low

      def index
        respond_to do |format|
          format.html
          format.json do
            @images = ContainerRepositoriesFinder.new(user: current_user, subject: group, params: params.slice(:name))
                                                 .execute
                                                 .with_api_entity_associations

            track_package_event(:list_repositories, :container, user: current_user, namespace: group)

            serializer = ContainerRepositoriesSerializer
              .new(current_user: current_user)

            render json: serializer.with_pagination(request, response)
              .represent_read_only(@images)
          end
        end
      end

      # The show action renders index to allow frontend routing to work on page refresh
      def show
        render :index
      end

      private

      def verify_container_registry_enabled!
        render_404 unless Gitlab.config.registry.enabled
      end

      def authorize_read_container_image!
        render_404 unless can?(current_user, :read_container_image, group)
      end
    end
  end
end
