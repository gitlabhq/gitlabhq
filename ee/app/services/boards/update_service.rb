module Boards
  class UpdateService < Boards::BaseService
    def execute(board)
      unless parent.feature_available?(:scoped_issue_board)
        params.delete(:milestone_id)
        params.delete(:assignee_id)
        params.delete(:label_ids)
        params.delete(:weight)
      end

      set_assignee
      set_milestone

      board.update(params)
    end
  end
end
