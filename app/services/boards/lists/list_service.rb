module Boards
  module Lists
    class ListService < BaseService
      def execute(board)
        board.lists.create(list_type: :backlog) unless board.lists.backlog.any?

        board.lists
      end
    end
  end
end
