module Boards
  class DestroyService < Boards::BaseService
    def execute(board)
      return false if project.boards.size == 1

      board.destroy
    end
  end
end
