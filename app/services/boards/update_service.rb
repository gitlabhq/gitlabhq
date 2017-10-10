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

      board.update(params)
    end

    def set_assignee
      assignee = User.find_by(id: params.delete(:assignee_id))
      params.merge!(assignee: assignee)
    end
  end
end
