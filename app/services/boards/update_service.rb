module Boards
  class UpdateService < Boards::BaseService
    def execute(board)
      params.delete(:milestone_id) unless parent.feature_available?(:issue_board_milestone)

      board.update(params)
    end
  end
end
