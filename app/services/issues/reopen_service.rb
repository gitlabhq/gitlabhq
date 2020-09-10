# frozen_string_literal: true

module Issues
  class ReopenService < Issues::BaseService
    def execute(issue)
      return issue unless can?(current_user, :reopen_issue, issue)

      if issue.reopen
        event_service.reopen_issue(issue, current_user)
        create_note(issue, 'reopened')
        notification_service.async.reopen_issue(issue, current_user)
        execute_hooks(issue, 'reopen')
        invalidate_cache_counts(issue, users: issue.assignees)
        issue.update_project_counter_caches
        delete_milestone_closed_issue_counter_cache(issue.milestone)
        track_incident_action(current_user, issue, :incident_reopened)
      end

      issue
    end

    private

    def create_note(issue, state = issue.state)
      SystemNoteService.change_status(issue, issue.project, current_user, state, nil)
    end
  end
end
