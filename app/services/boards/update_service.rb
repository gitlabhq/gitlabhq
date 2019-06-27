# frozen_string_literal: true

module Boards
  class UpdateService < Boards::BaseService
    def execute(board)
      board.update(params)
    end
  end
end
