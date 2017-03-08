module Boards
  class DestroyService < BaseService
    def execute(board)
      return false if project.boards.size == 1

      board.destroy
    end
  end
end
