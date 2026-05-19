# frozen_string_literal: true

module Boards
  module Issues
    class ListService < Boards::BaseItemsListService
      include Gitlab::Utils::StrongMemoize

      def self.valid_params
        IssuesFinder.valid_params
      end

      # It is a class method because we cannot apply it
      # prior to knowing how many items should be fetched for a list.
      def self.initialize_relative_positions(board, current_user, issues)
        if Gitlab::Database.read_write? && !board.disabled_for?(current_user)
          Issue.move_nulls_to_end(issues)
        end
      end

      private

      def order(items)
        return items.order_closed_at_desc if list&.closed?

        items.order_by_relative_position
      end

      def finder
        IssuesFinder.new(current_user, filter_params)
      end

      def board
        @board ||= parent.boards.find(params[:board_id])
      end

      def filter_params
        set_scope
        set_non_archived
        set_work_item_type_ids

        super
      end

      def set_scope
        params[:include_subgroups] = board.group_board?
      end

      def set_non_archived
        params[:non_archived] = parent.is_a?(Group)
      end

      def set_work_item_type_ids
        work_item_type_ids = work_item_type_provider.filtered_types.filter_map do |type|
          type.try(:converted_from_system_defined_type_identifier) || type.id if type.filterable_board_view?
        end
        params[:work_item_type_ids] ||= work_item_type_ids
      end

      def item_model
        Issue
      end

      def work_item_type_provider
        ::WorkItems::TypesFramework::Provider.new(parent)
      end
    end
  end
end

Boards::Issues::ListService.prepend_mod_with('Boards::Issues::ListService')
