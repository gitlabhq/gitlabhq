module Boards
  class UpdateService < Boards::BaseService
    def execute(board)
      board.update(name: params[:name])
    end
  end
end
