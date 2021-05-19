# frozen_string_literal: true

module Boards
  module Lists
    class ListService < Boards::BaseService
      def execute(board, create_default_lists: true)
        if create_default_lists && !board.lists.backlog.exists?
          board.lists.create(list_type: :backlog)
        end

        lists = board.lists.preload_associated_models

        return lists.id_in(params[:list_id]) if params[:list_id].present?

        list_types = unavailable_list_types_for(board)
        lists.without_types(list_types)
      end

      private

      def unavailable_list_types_for(board)
        hidden_lists_for(board)
      end

      def hidden_lists_for(board)
        [].tap do |hidden|
          hidden << ::List.list_types[:backlog] if board.hide_backlog_list?
          hidden << ::List.list_types[:closed] if board.hide_closed_list?
        end
      end
    end
  end
end

Boards::Lists::ListService.prepend_mod_with('Boards::Lists::ListService')
