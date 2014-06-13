module Issues
  class BaseService < ::BaseService

    private

    def create_assignee_note(issue)
      Note.create_assignee_change_note(issue, issue.project, current_user, issue.assignee)
    end

    def execute_hooks(issue, action = 'open')
      issue_data = issue.to_hook_data
      issue_url = Gitlab::UrlBuilder.new(:issue).build(issue.id)
      issue_data[:object_attributes].merge!(url: issue_url, action: action)
      issue.project.execute_hooks(issue_data, :issue_hooks)
    end

    def create_milestone_note(issue)
      Note.create_milestone_change_note(issue, issue.project, current_user, issue.milestone)
    end
  end
end
