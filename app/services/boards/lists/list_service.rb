module Boards
  module Lists
    class ListService < Boards::BaseService
      prepend ::EE::Boards::Lists::ListService

      def execute(board)
        board.lists.create(list_type: :backlog) unless board.lists.backlog.exists?

        board.lists
      end
    end
  end
end
