# frozen_string_literal: true

module WorkItems
  module SavedViews
    class ReorderService < BaseService
      attr_reader :current_user, :params

      def initialize(current_user:, params:)
        @current_user = current_user
        @params = params
      end

      def execute(saved_view)
        if saved_view.id == adjacent_id
          return ServiceResponse.error(message: "Cannot reorder a saved view relative to itself")
        end

        user_saved_view_to_move = user_saved_views_scope(saved_view).for_saved_view(saved_view).first
        adjacent_saved_view = find_adjacent(saved_view)

        unless user_saved_view_to_move && adjacent_saved_view
          return ServiceResponse.error(message: "Unable to find subscribed saved view(s)")
        end

        reorder(user_saved_view_to_move, adjacent_saved_view)
        user_saved_view_to_move.save!

        ServiceResponse.success(payload: { user_saved_view: user_saved_view_to_move })
      end

      private

      def adjacent_id
        params[:move_before_id] || params[:move_after_id]
      end

      def user_saved_views_scope(saved_view)
        ::WorkItems::SavedViews::UserSavedView.in_namespace(saved_view.namespace).for_user(current_user)
      end

      def find_adjacent(saved_view)
        adjacent_saved_view = ::WorkItems::SavedViews::SavedView.id_in(adjacent_id).first
        return unless adjacent_saved_view

        user_saved_views_scope(saved_view).for_saved_view(adjacent_saved_view).first
      end

      def reorder(user_saved_view_to_move, adjacent_saved_view)
        if params[:move_before_id]
          user_saved_view_to_move.move_between(nil, adjacent_saved_view)
        else
          user_saved_view_to_move.move_between(adjacent_saved_view, nil)
        end
      end
    end
  end
end
