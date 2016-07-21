module Issues
  class BulkUpdateService < BaseService
    def execute
      issues_ids   = params.delete(:issues_ids).split(",")
      issue_params = params

      %i(state_event milestone_id assignee_id add_label_ids remove_label_ids subscription_event).each do |key|
        issue_params.delete(key) unless issue_params[key].present?
      end

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
