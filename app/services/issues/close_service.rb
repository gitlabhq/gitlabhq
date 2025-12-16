# frozen_string_literal: true

module Issues
  class CloseService < Issues::BaseService
    include ::Gitlab::Loggable

    # Closes the supplied issue if the current user is able to do so.
    def execute(issue, commit: nil, notifications: true, system_note: true, skip_authorization: false, status: nil)
      unless can_close?(issue, skip_authorization: skip_authorization)
        log_failed_auth(issue, commit)
        return issue
      end

      close_issue(issue, closed_via: commit, notifications: notifications, system_note: system_note, status: status)
    end

    # Closes the supplied issue without checking if the user is authorized to
    # do so.
    #
    # The code calling this method is responsible for ensuring that a user is
    # allowed to close the given issue.
    def close_issue(issue, closed_via: nil, notifications: true, system_note: true, status: nil)
      if issue.is_a?(ExternalIssue)
        close_external_issue(issue, closed_via)

        return issue
      end

      return issue unless handle_closing_issue!(issue, current_user)

      after_close(issue, status, closed_via: closed_via, notifications: notifications, system_note: system_note)
    end

    private

    def log_failed_auth(issue, commit)
      log_info = {
        message: 'Unauthorized close issue',
        issue_id: issue&.id,
        current_user_id: current_user&.id
      }
      log_info[:commit] = commit.id if commit.is_a?(::Commit)
      log_info[:merge_request_id] = commit.id if commit.is_a?(::MergeRequest)

      ::Gitlab::AppLogger.info(build_structured_payload(**log_info))
    end

    # overriden in EE
    def handle_closing_issue!(issue, current_user)
      issue.close(current_user)
    end

    # overriden in EE
    def after_close(issue, _status, closed_via: nil, notifications: true, system_note: true)
      event_service.close_issue(issue, current_user)
      create_note(issue, closed_via) if system_note

      if current_user.project_bot?
        log_audit_event(issue, current_user, "#{issue.issue_type}_closed_by_project_bot",
          "Closed #{issue.issue_type.humanize(capitalize: false)} #{issue.title}")
      end

      closed_via = _("commit %{commit_id}") % { commit_id: closed_via.id } if closed_via.is_a?(Commit)

      if notifications
        user = current_user
        issue.run_after_commit_or_now do
          NotificationService.new.async.close_issue(issue, user, { closed_via: closed_via })
        end
      end

      todo_service.close_issue(issue, current_user)
      perform_incident_management_actions(issue)
      execute_hooks(issue, 'close')
      invalidate_cache_counts(issue, users: issue.assignees)
      issue.invalidate_project_counter_caches
      track_incident_action(current_user, issue, :incident_closed)

      store_first_mentioned_in_commit_at(issue, closed_via) if closed_via.is_a?(MergeRequest)

      Milestones::ClosedIssuesCountService.new(issue.milestone).delete_cache if issue.milestone

      track_work_item_close(issue)
      GraphqlTriggers.work_item_updated(issue)

      issue
    end

    def can_close?(issue, skip_authorization: false)
      skip_authorization || can?(current_user, :update_issue, issue) || issue.is_a?(ExternalIssue)
    end

    def perform_incident_management_actions(issue)
      resolve_alerts(issue)
      resolve_incident(issue)
    end

    def close_external_issue(issue, closed_via)
      return unless project.external_issue_tracker&.support_close_issue?

      project.external_issue_tracker.close_issue(closed_via, issue, current_user)
      todo_service.close_issue(issue, current_user)
    end

    def create_note(issue, current_commit)
      SystemNoteService.change_status(issue, issue.project, current_user, issue.state, current_commit)
    end

    def resolve_alerts(issue)
      issue.alert_management_alerts.each { |alert| resolve_alert(alert) }
    end

    def resolve_alert(alert)
      return if alert.resolved?

      issue = alert.issue

      if alert.resolve
        SystemNoteService.change_alert_status(alert, Users::Internal.alert_bot, " because #{current_user.to_reference} closed incident #{issue.to_reference(project)}")
      else
        Gitlab::AppLogger.warn(
          message: 'Cannot resolve an associated Alert Management alert',
          issue_id: issue.id,
          alert_id: alert.id,
          alert_errors: alert.errors.messages
        )
      end
    end

    def resolve_incident(issue)
      return unless issue.work_item_type&.incident?

      status = issue.incident_management_issuable_escalation_status || issue.build_incident_management_issuable_escalation_status

      return unless status.resolve

      SystemNoteService.change_incident_status(issue, current_user, ' by closing the incident')
      IncidentManagement::TimelineEvents::CreateService.resolve_incident(issue, current_user)
    end

    def store_first_mentioned_in_commit_at(issue, merge_request, max_commit_lookup: 100)
      metrics = issue.metrics
      return if metrics.nil? || metrics.first_mentioned_in_commit_at

      first_commit_timestamp = merge_request.commits(limit: max_commit_lookup).last.try(:authored_date)
      return unless first_commit_timestamp

      metrics.update!(first_mentioned_in_commit_at: first_commit_timestamp)
    end

    def track_work_item_close(work_item)
      ::Gitlab::WorkItems::Instrumentation::TrackingService.new(
        work_item: work_item,
        current_user: current_user,
        event: Gitlab::WorkItems::Instrumentation::EventActions::CLOSE
      ).execute
    end
  end
end

Issues::CloseService.prepend_mod_with('Issues::CloseService')
