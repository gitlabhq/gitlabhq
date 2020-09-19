# frozen_string_literal: true

module Boards
  class DestroyService < Boards::BaseService
    def execute(board)
      if parent.boards.size == 1
        return ServiceResponse.error(message: "The board could not be deleted, because the parent doesn't have any other boards.")
      end

      board.destroy!

      ServiceResponse.success
    end
  end
end
