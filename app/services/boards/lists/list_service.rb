module Boards
  module Lists
    class ListService < Boards::BaseService
      def execute(board)
        board.lists
      end
    end
  end
end
