module Boards
  class UpdateService < BaseService
    def execute(board)
      board.update(name: params[:name])
    end
  end
end
