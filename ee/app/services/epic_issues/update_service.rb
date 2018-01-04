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
    rescue ActiveRecord::RecordNotFound
      return error('Epic issue not found for given params', 404)
    end

    private

    def move_issue
      before_epic_issue = epic.epic_issues.find(params[:move_before_id]) if params[:move_before_id]
      after_epic_issue = epic.epic_issues.find(params[:move_after_id]) if params[:move_after_id]

      epic_issue.move_between(before_epic_issue, after_epic_issue)
    end

    def epic
      epic_issue.epic
    end
  end
end
