# frozen_string_literal: true

module WorkItems
  module SavedViews
    class CreateService < BaseService
      attr_reader :current_user, :container, :params

      def initialize(current_user:, container:, params:)
        @current_user = current_user
        @container = container
        @params = params
      end

      def execute
        unless Ability.allowed?(current_user, :create_saved_view, container)
          return ServiceResponse.error(
            message: _('You do not have permission to create saved views in this namespace.')
          )
        end

        filter_response = filter_service.execute
        return filter_response unless filter_response.success?

        saved_view = ::WorkItems::SavedViews::SavedView.new(
          **params.except(:filters),
          namespace: container.is_a?(Project) ? container.project_namespace : container,
          created_by_id: current_user.id,
          updated_by_id: current_user.id,
          filter_data: filter_response.payload,
          version: 1
        )

        if saved_view.save
          auto_subscribe_creator(saved_view)
          track_saved_view_create(saved_view)
          ServiceResponse.success(payload: { saved_view: saved_view })
        else
          ServiceResponse.error(message: saved_view.errors.full_messages)
        end
      end

      private

      def filter_service
        FilterNormalizerService.new(filter_data: params[:filters], container: container, current_user: current_user)
      end

      def auto_subscribe_creator(saved_view)
        UserSavedView.subscribe(user: current_user, saved_view: saved_view, auto_unsubscribe: true)
      end

      def track_saved_view_create(saved_view)
        ::Gitlab::WorkItems::Instrumentation::TrackingService.track(
          event: ::Gitlab::WorkItems::Instrumentation::EventActions::SAVED_VIEW_CREATE,
          properties: {
            user: current_user,
            namespace: saved_view.namespace,
            project: container.is_a?(Project) ? container : nil,
            additional_properties: {
              property: saved_view.namespace.user_role(current_user)
            }
          }
        )
      end
    end
  end
end
