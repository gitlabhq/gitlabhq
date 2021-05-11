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
      if issue.is_a?(ExternalIssue)
        close_external_issue(issue, closed_via)

        return issue
      end

      if project.issues_enabled? && issue.close(current_user)
        event_service.close_issue(issue, current_user)
        create_note(issue, closed_via) if system_note

        closed_via = _("commit %{commit_id}") % { commit_id: closed_via.id } if closed_via.is_a?(Commit)

        notification_service.async.close_issue(issue, current_user, { closed_via: closed_via }) if notifications
        todo_service.close_issue(issue, current_user)
        resolve_alert(issue)
        execute_hooks(issue, 'close')
        invalidate_cache_counts(issue, users: issue.assignees)
        issue.update_project_counter_caches
        track_incident_action(current_user, issue, :incident_closed)

        if closed_via.is_a?(MergeRequest)
          store_first_mentioned_in_commit_at(issue, closed_via)
          OnboardingProgressService.new(project.namespace).execute(action: :issue_auto_closed)
        end

        delete_milestone_closed_issue_counter_cache(issue.milestone)
      end

      issue
    end

    private

    def close_external_issue(issue, closed_via)
      return unless project.external_issue_tracker&.support_close_issue?

      project.external_issue_tracker.close_issue(closed_via, issue, current_user)
      todo_service.close_issue(issue, current_user)
    end

    def create_note(issue, current_commit)
      SystemNoteService.change_status(issue, issue.project, current_user, issue.state, current_commit)
    end

    def resolve_alert(issue)
      return unless alert = issue.alert_management_alert
      return if alert.resolved?

      if alert.resolve
        SystemNotes::AlertManagementService.new(noteable: alert, project: alert.project, author: current_user).closed_alert_issue(issue)
      else
        Gitlab::AppLogger.warn(
          message: 'Cannot resolve an associated Alert Management alert',
          issue_id: issue.id,
          alert_id: alert.id,
          alert_errors: alert.errors.messages
        )
      end
    end

    def store_first_mentioned_in_commit_at(issue, merge_request)
      metrics = issue.metrics
      return if metrics.nil? || metrics.first_mentioned_in_commit_at

      first_commit_timestamp = merge_request.commits(limit: 1).first.try(:authored_date)
      return unless first_commit_timestamp

      metrics.update!(first_mentioned_in_commit_at: first_commit_timestamp)
    end
  end
end
