module Issues
  class BaseService < ::BaseService

    private

    def create_assignee_note(issue)
      Note.create_assignee_change_note(issue, issue.project, current_user, issue.assignee)
    end

    def execute_hooks(issue)
      issue.project.execute_hooks(issue.to_hook_data, :issue_hooks)
    end
  end
end
