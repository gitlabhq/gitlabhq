module Boards
  module Lists
    class ListService < BaseService
      def execute(board)
        board.lists
      end
    end
  end
end
