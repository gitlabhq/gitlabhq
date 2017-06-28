module Issues
  class BaseService < ::IssuableBaseService
    def hook_data(issue, action)
      issue_data = issue.to_hook_data(current_user)
      issue_url = Gitlab::UrlBuilder.build(issue)
      issue_data[:object_attributes].merge!(url: issue_url, action: action)
      issue_data
    end

    private

    def create_assignee_note(issue, old_assignees)
      SystemNoteService.change_issue_assignees(
        issue, issue.project, current_user, old_assignees)
    end

    def execute_hooks(issue, action = 'open')
      issue_data  = hook_data(issue, action)
      hooks_scope = issue.confidential? ? :confidential_issue_hooks : :issue_hooks
      issue.project.execute_hooks(issue_data, hooks_scope)
      issue.project.execute_services(issue_data, hooks_scope)
    end

    def filter_assignee(issuable)
      return if params[:assignee_ids].blank?

      # The number of assignees is limited by one for GitLab CE
      params[:assignee_ids] = params[:assignee_ids][0, 1]

      assignee_ids = params[:assignee_ids].select { |assignee_id| assignee_can_read?(issuable, assignee_id) }

      if params[:assignee_ids].map(&:to_s) == [IssuableFinder::NONE]
        params[:assignee_ids] = []
      elsif assignee_ids.any?
        params[:assignee_ids] = assignee_ids
      else
        params.delete(:assignee_ids)
      end
    end
  end
end
