# frozen_string_literal: true

module Boards
  module Lists
    class ListService < Boards::BaseService
      def execute(board)
        board.lists.create(list_type: :backlog) unless board.lists.backlog.exists?

        board.lists.preload_associated_models
      end
    end
  end
end

Boards::Lists::ListService.prepend_if_ee('EE::Boards::Lists::ListService')
