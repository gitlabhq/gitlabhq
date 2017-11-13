module Issues
  class CloseService < Issues::BaseService
    # Closes the supplied issue if the current user is able to do so.
    def execute(issue, commit: nil, notifications: true, system_note: true)
      return issue unless can?(current_user, :update_issue, issue)

      close_issue(issue,
                  commit: commit,
                  notifications: notifications,
                  system_note: system_note)
    end

    # Closes the supplied issue without checking if the user is authorized to
    # do so.
    #
    # The code calling this method is responsible for ensuring that a user is
    # allowed to close the given issue.
    def close_issue(issue, commit: nil, notifications: true, system_note: true)
      if project.jira_tracker? && project.jira_service.active && issue.is_a?(ExternalIssue)
        project.jira_service.close_issue(commit, issue)
        todo_service.close_issue(issue, current_user)
        return issue
      end

      if project.issues_enabled? && issue.close
        event_service.close_issue(issue, current_user)
        create_note(issue, commit) if system_note
        notification_service.close_issue(issue, current_user) if notifications
        todo_service.close_issue(issue, current_user)
        execute_hooks(issue, 'close')
        invalidate_cache_counts(issue, users: issue.assignees)
        issue.update_project_counter_caches
      end

      issue
    end

    private

    def create_note(issue, current_commit)
      SystemNoteService.change_status(issue, issue.project, current_user, issue.state, current_commit)
    end
  end
end
