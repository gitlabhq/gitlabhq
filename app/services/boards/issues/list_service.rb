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
        set_issue_types

        super
      end

      def set_scope
        params[:include_subgroups] = board.group_board?
      end

      def set_non_archived
        params[:non_archived] = parent.is_a?(Group)
      end

      def set_issue_types
        types = Issue::TYPES_FOR_BOARD_LIST.dup
        types << 'task' if should_include_task?
        params[:issue_types] ||= types
      end

      def should_include_task?
        parent&.work_items_beta_feature_flag_enabled? ||
          current_user&.user_preference&.use_work_items_view?
      end

      def item_model
        Issue
      end
    end
  end
end

Boards::Issues::ListService.prepend_mod_with('Boards::Issues::ListService')
