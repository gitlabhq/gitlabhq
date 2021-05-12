# frozen_string_literal: true

module ErrorTracking
  class IssueUpdateService < ErrorTracking::BaseService
    private

    def perform
      response = project_error_tracking_setting.update_issue(
        issue_id: params[:issue_id],
        params: update_params
      )

      compose_response(response) do
        project_error_tracking_setting.expire_issues_cache
        response[:closed_issue_iid] = update_related_issue&.iid
      end
    end

    def update_related_issue
      issue = related_issue
      return unless issue

      close_and_create_note(issue)
    end

    def close_and_create_note(issue)
      return unless resolving? && issue.opened?

      processed_issue = close_issue(issue)
      return unless processed_issue.reset.closed?

      create_system_note(processed_issue)
      processed_issue
    end

    def close_issue(issue)
      Issues::CloseService
        .new(project: project, current_user: current_user)
        .execute(issue, system_note: false)
    end

    def create_system_note(issue)
      SystemNoteService.close_after_error_tracking_resolve(issue, project, current_user)
    end

    def related_issue
      SentryIssueFinder
        .new(project, current_user: current_user)
        .execute(params[:issue_id])
        &.issue
    end

    def resolving?
      update_params[:status] == 'resolved'
    end

    def update_params
      params.except(:issue_id)
    end

    def parse_response(response)
      {
        updated: response[:updated].present?,
        closed_issue_iid: response[:closed_issue_iid]
      }
    end

    def unauthorized
      return error('Error Tracking is not enabled') unless enabled?
      return error('Access denied', :unauthorized) unless can_update?
    end
  end
end
