# frozen_string_literal: true

module Boards
  class DestroyService < Boards::BaseService
    def execute(board)
      return false if parent.boards.size == 1

      board.destroy
    end
  end
end
