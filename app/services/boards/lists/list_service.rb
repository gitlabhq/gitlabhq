# frozen_string_literal: true

module Boards
  module Lists
    class ListService < Boards::BaseService
      def execute(board, create_default_lists: true)
        if create_default_lists && !board.lists.backlog.exists?
          board.lists.create(list_type: :backlog)
        end

        board.lists.preload_associated_models
      end
    end
  end
end

Boards::Lists::ListService.prepend_if_ee('EE::Boards::Lists::ListService')
