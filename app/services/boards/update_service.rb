module Boards
  class UpdateService < Boards::BaseService
    def execute(board)
      params.delete(:milestone_id) unless parent.feature_available?(:scoped_issue_board)

      board.update(params)
    end
  end
end
