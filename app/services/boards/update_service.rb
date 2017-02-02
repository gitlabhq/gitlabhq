module Boards
  class UpdateService < BaseService
    def execute(board)
      board.update(name: params[:name])
      board.update(milestone_id: params[:milestone_id])
    end
  end
end
