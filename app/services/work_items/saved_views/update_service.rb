# frozen_string_literal: true

module WorkItems
  module SavedViews
    class UpdateService < BaseService
      attr_reader :current_user, :saved_view, :params, :container

      def initialize(current_user:, saved_view:, params:)
        @current_user = current_user
        @saved_view = saved_view
        @params = params
        @container = saved_view.namespace.owner_entity
      end

      def execute
        unless container.work_items_saved_views_enabled?(current_user)
          return ServiceResponse.error(message: _('Saved views are not enabled for this namespace.'))
        end

        unless Ability.allowed?(current_user, :update_saved_view, saved_view)
          return ServiceResponse.error(
            message: _('You do not have permission to update this saved view.')
          )
        end

        if updating_visibility? && !can_update_visibility?
          return ServiceResponse.error(message: _('Only the author can change visibility settings'))
        end

        if params[:filters]
          filter_response = normalize_filters!
          return filter_response unless filter_response.success?

          params[:filter_data] = filter_response.payload
          params.delete(:filters)
        end

        # Check before the update, since updating could change the view to private before we check this
        changing_to_private = changing_to_private?

        SavedView.transaction do
          if saved_view.update(params)
            saved_view.unsubscribe_other_users!(user: current_user) if changing_to_private
            ServiceResponse.success(payload: { saved_view: saved_view })
          else
            ServiceResponse.error(message: saved_view.errors.full_messages)
          end
        end
      end

      private

      def updating_visibility?
        params.key?(:private)
      end

      def can_update_visibility?
        Ability.allowed?(current_user, :update_saved_view_visibility, saved_view)
      end

      def normalize_filters!
        filter_response = FilterNormalizerService.new(
          filter_data: params[:filters], container: container, current_user: current_user
        ).execute

        return filter_response unless filter_response.success?

        ServiceResponse.success(payload: filter_response.payload)
      end

      def changing_to_private?
        params[:private] == true && !saved_view.private?
      end
    end
  end
end
