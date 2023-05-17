# frozen_string_literal: true

module Issues
  class ReopenService < Issues::BaseService
    def execute(issue, skip_authorization: false)
      return issue unless can_reopen?(issue, skip_authorization: skip_authorization)

      if issue.reopen
        event_service.reopen_issue(issue, current_user)
        create_note(issue, 'reopened')
        notification_service.async.reopen_issue(issue, current_user)
        perform_incident_management_actions(issue)
        execute_hooks(issue, 'reopen')
        invalidate_cache_counts(issue, users: issue.assignees)
        issue.update_project_counter_caches
        Milestones::ClosedIssuesCountService.new(issue.milestone).delete_cache if issue.milestone
        track_incident_action(current_user, issue, :incident_reopened)
      end

      issue
    end

    private

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
