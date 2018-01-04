module EpicIssues
  class UpdateService < BaseService
    attr_reader :epic_issue, :current_user, :params

    def initialize(epic_issue, user, params)
      @epic_issue = epic_issue
      @current_user = user
      @params = params
    end

    def execute
      move_issue if params[:move_after_id] || params[:move_before_id]
      epic_issue.save!
      success
    end

    private

    def move_issue
      before_epic_issue = EpicIssue.find_by(id: params[:move_before_id])
      after_epic_issue = EpicIssue.find_by(id: params[:move_after_id])

      epic_issue.move_between(before_epic_issue, after_epic_issue)
    end
  end
end
