module Issues
  class BaseService < ::BaseService

    private

    # Create issue note with service comment like 'Status changed to closed'
    def create_note(issue)
      Note.create_status_change_note(issue, issue.project, current_user, issue.state, current_commit)
    end

    def create_assignee_note(issue)
      Note.create_assignee_change_note(issue, issue.project, current_user, issue.assignee)
    end

    def execute_hooks(issue)
      issue.project.execute_hooks(issue.to_hook_data, :issue_hooks)
    end
  end
end
