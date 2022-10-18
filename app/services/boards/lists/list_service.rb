# frozen_string_literal: true

module Boards
  module Lists
    class ListService < Boards::BaseService
      def execute(board, create_default_lists: true)
        if create_default_lists && !board.lists.backlog.exists?
          board.lists.create(list_type: :backlog)
        end

        lists = board.lists.preload_associated_models
        lists = lists.with_types(available_list_types_for(board))

        return lists.id_in(params[:list_id]) if params[:list_id].present?

        lists
      end

      private

      def available_list_types_for(board)
        licensed_list_types(board) + visible_lists(board)
      end

      def licensed_list_types(board)
        [List.list_types[:label]]
      end

      def visible_lists(board)
        [].tap do |visible|
          visible << ::List.list_types[:backlog] unless board.hide_backlog_list?
          visible << ::List.list_types[:closed] unless board.hide_closed_list?
        end
      end
    end
  end
end

Boards::Lists::ListService.prepend_mod_with('Boards::Lists::ListService')
