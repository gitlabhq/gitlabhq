# frozen_string_literal: true

module Issues
  class ReopenService < Issues::BaseService
    def execute(issue, skip_authorization: false)
      return issue unless can_reopen?(issue, skip_authorization: skip_authorization)

      after_reopen(issue) if reopen_issue(issue)

      issue
    end

    private

    # overriden in EE
    def after_reopen(issue)
      event_service.reopen_issue(issue, current_user)

      if current_user.project_bot?
        log_audit_event(issue, current_user, "#{issue.issue_type}_reopened_by_project_bot",
          "Reopened #{issue.issue_type.humanize(capitalize: false)} #{issue.title}")
      end

      create_note(issue, 'reopened')
      notification_service.async.reopen_issue(issue, current_user)
      perform_incident_management_actions(issue)
      execute_hooks(issue, 'reopen')
      invalidate_cache_counts(issue, users: issue.assignees)
      issue.update_project_counter_caches
      Milestones::ClosedIssuesCountService.new(issue.milestone).delete_cache if issue.milestone
      track_incident_action(current_user, issue, :incident_reopened)
    end

    # overriden in EE
    def reopen_issue(issue)
      issue.reopen
    end

    def can_reopen?(issue, skip_authorization: false)
      skip_authorization || can?(current_user, :reopen_issue, issue)
    end

    def perform_incident_management_actions(issue)
      return unless issue.work_item_type&.incident?

      create_timeline_event(issue)
    end

    def create_note(issue, state = issue.state)
      SystemNoteService.change_status(issue, issue.project, current_user, state, nil)
    end

    def create_timeline_event(issue)
      IncidentManagement::TimelineEvents::CreateService.reopen_incident(issue, current_user)
    end
  end
end

Issues::ReopenService.prepend_mod_with('Issues::ReopenService')
