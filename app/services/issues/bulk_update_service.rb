module Issues
  class BulkUpdateService < BaseService
    def execute
      update_data = params[:update]

      issues_ids   = update_data[:issues_ids].split(",")
      milestone_id = update_data[:milestone_id]
      assignee_id  = update_data[:assignee_id]
      status       = update_data[:status]

      new_state = nil

      if status.present?
        if status == 'closed'
          new_state = :close
        else
          new_state = :reopen
        end
      end

      opts = {}
      opts[:milestone_id] = milestone_id if milestone_id.present?
      opts[:assignee_id] = assignee_id if assignee_id.present?

      issues = Issue.where(id: issues_ids)
      issues = issues.select { |issue| can?(current_user, :modify_issue, issue) }

      issues.each do |issue|
        issue.update_attributes(opts)
        issue.send new_state if new_state
      end

      {
        count: issues.count,
        success: !issues.count.zero?
      }
    end
  end
end
