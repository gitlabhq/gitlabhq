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
        unless container&.work_items_saved_views_enabled?(current_user)
          return ServiceResponse.error(message: 'Saved views are not enabled for this namespace.')
        end

        unless Ability.allowed?(current_user, :create_saved_view, container)
          return ServiceResponse.error(message: 'You do not have permission to create saved views in this namespace.')
        end

        filter_data = normalize_filters!(params)

        # If the normalization failed, return the error
        return filter_data unless filter_data.is_a?(Hash)

        saved_view = ::WorkItems::SavedViews::SavedView.new(
          **params,
          namespace: container.is_a?(Project) ? container.project_namespace : container,
          created_by_id: current_user.id,
          filter_data: filter_data,
          version: 1
        )

        if saved_view.save
          ServiceResponse.success(payload: { saved_view: saved_view })
        else
          ServiceResponse.error(message: saved_view.errors.full_messages)
        end
      end

      def normalize_filters!(params)
        filter_response = FilterNormalizerService.new(
          filter_data: params[:filters], container: container, current_user: current_user
        ).execute

        return filter_response unless filter_response.success?

        params.delete(:filters)
        filter_response.payload
      end
    end
  end
end
