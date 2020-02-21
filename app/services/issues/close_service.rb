# frozen_string_literal: true

module Issues
  class CloseService < Issues::BaseService
    # Closes the supplied issue if the current user is able to do so.
    def execute(issue, commit: nil, notifications: true, system_note: true)
      return issue unless can?(current_user, :update_issue, issue) || issue.is_a?(ExternalIssue)

      close_issue(issue,
                  closed_via: commit,
                  notifications: notifications,
                  system_note: system_note)
    end

    # Closes the supplied issue without checking if the user is authorized to
    # do so.
    #
    # The code calling this method is responsible for ensuring that a user is
    # allowed to close the given issue.
    def close_issue(issue, closed_via: nil, notifications: true, system_note: true)
      if project.jira_tracker_active? && issue.is_a?(ExternalIssue)
        project.jira_service.close_issue(closed_via, issue)
        todo_service.close_issue(issue, current_user)
        return issue
      end

      if project.issues_enabled? && issue.close
        issue.update(closed_by: current_user)
        event_service.close_issue(issue, current_user)
        create_note(issue, closed_via) if system_note

        closed_via = _("commit %{commit_id}") % { commit_id: closed_via.id } if closed_via.is_a?(Commit)

        notification_service.async.close_issue(issue, current_user, closed_via: closed_via) if notifications
        todo_service.close_issue(issue, current_user)
        execute_hooks(issue, 'close')
        invalidate_cache_counts(issue, users: issue.assignees)
        issue.update_project_counter_caches

        store_first_mentioned_in_commit_at(issue, closed_via) if closed_via.is_a?(MergeRequest)
      end

      issue
    end

    private

    def create_note(issue, current_commit)
      SystemNoteService.change_status(issue, issue.project, current_user, issue.state, current_commit)
    end

    def store_first_mentioned_in_commit_at(issue, merge_request)
      return unless Feature.enabled?(:store_first_mentioned_in_commit_on_issue_close, issue.project)

      metrics = issue.metrics
      return if metrics.nil? || metrics.first_mentioned_in_commit_at

      first_commit_timestamp = merge_request.commits(limit: 1).first&.date
      return unless first_commit_timestamp

      metrics.update!(first_mentioned_in_commit_at: first_commit_timestamp)
    end
  end
end
