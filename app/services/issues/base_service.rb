module Issues
  class BaseService < ::IssuableBaseService
    def hook_data(issue, action)
      issue_data = issue.to_hook_data(current_user)
      issue_url = Gitlab::UrlBuilder.build(issue)
      issue_data[:object_attributes].merge!(url: issue_url, action: action)
      issue_data
    end

    private

    def create_assignee_note(issue)
      SystemNoteService.change_issue_assignees(
        issue, issue.project, current_user, issue.assignees)
    end

    def execute_hooks(issue, action = 'open')
      issue_data  = hook_data(issue, action)
      hooks_scope = issue.confidential? ? :confidential_issue_hooks : :issue_hooks
      issue.project.execute_hooks(issue_data, hooks_scope)
      issue.project.execute_services(issue_data, hooks_scope)
    end

    def filter_assignee(issuable)
      return if params[:assignee_ids].blank?

      assignee_ids = params[:assignee_ids].split(',').map(&:strip)

      if assignee_ids == [ IssuableFinder::NONE ]
        params[:assignee_ids] = ""
      else
        params.delete(:assignee_ids) unless assignee_ids.all?{ |assignee_id| assignee_can_read?(issuable, assignee_id)}
      end
    end
  end
end
