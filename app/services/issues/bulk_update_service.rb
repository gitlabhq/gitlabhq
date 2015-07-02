module Issues
  class BulkUpdateService < BaseService
    def execute
      issues_ids   = params.delete(:issues_ids).split(",")
      issue_params = params

      issue_params.delete(:state_event)   unless issue_params[:state_event].present?
      issue_params.delete(:milestone_id)  unless issue_params[:milestone_id].present?
      issue_params.delete(:assignee_id)   unless issue_params[:assignee_id].present?

      issues = Issue.where(id: issues_ids)
      issues.each do |issue|
        next unless can?(current_user, :update_issue, issue)

        Issues::UpdateService.new(issue.project, current_user, issue_params).execute(issue)
      end

      {
        count:    issues.count,
        success:  !issues.count.zero?
      }
    end
  end
end
