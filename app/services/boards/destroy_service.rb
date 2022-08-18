# frozen_string_literal: true

module Boards
  class DestroyService < Boards::BaseService
    def execute(board)
      board.destroy!

      ServiceResponse.success
    end

    private

    def boards
      parent.boards
    end
  end
end
