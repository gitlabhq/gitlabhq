# frozen_string_literal: true

module ErrorTracking
  class IssueUpdateService < ErrorTracking::BaseService
    include ::Gitlab::Utils::StrongMemoize

    private

    def perform
      response = fetch

      unless parse_errors(response).present?
        response[:closed_issue_iid] = update_related_issue&.iid
        project_error_tracking_setting.expire_issues_cache
      end

      response
    end

    def fetch
      project_error_tracking_setting.update_issue(
        issue_id: params[:issue_id],
        params: update_params
      )
    end

    def update_related_issue
      return if related_issue.nil?

      close_and_create_note(related_issue)
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
        .new(project, current_user)
        .execute(issue, system_note: false)
    end

    def create_system_note(issue)
      SystemNoteService.close_after_error_tracking_resolve(issue, project, current_user)
    end

    def related_issue
      strong_memoize(:related_issue) do
        SentryIssueFinder
          .new(project, current_user: current_user)
          .execute(params[:issue_id])
          &.issue
      end
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

    def check_permissions
      return error('Error Tracking is not enabled') unless enabled?
      return error('Access denied', :unauthorized) unless can_update?
    end
  end
end
