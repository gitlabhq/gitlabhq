# frozen_string_literal: true

module Boards
  module Issues
    class ListService < Boards::BaseItemsListService
      include Gitlab::Utils::StrongMemoize

      def self.valid_params
        IssuesFinder.valid_params
      end

      private

      def order(items)
        return items.order_closed_date_desc if list&.closed?

        items.order_by_position_and_priority(with_cte: params[:search].present?)
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
        params[:issue_types] = Issue::TYPES_FOR_LIST
      end

      def item_model
        Issue
      end
    end
  end
end

Boards::Issues::ListService.prepend_mod_with('Boards::Issues::ListService')
