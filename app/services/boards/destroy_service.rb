module Boards
  class DestroyService < Boards::BaseService
    def execute(board)
      board.destroy
    end
  end
end
