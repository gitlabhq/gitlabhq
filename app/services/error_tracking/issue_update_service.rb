# frozen_string_literal: true

module ErrorTracking
  class IssueUpdateService < ErrorTracking::BaseService
    private

    def perform
      update_opts = {
        issue_id: params[:issue_id],
        params: update_params
      }

      response = update_issue(update_opts)

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
        .new(container: project, current_user: current_user)
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

    def update_issue(opts)
      # There are 2 types of the data source for the error tracking feature:
      #
      # * When integrated error tracking is enabled, we use the application database
      #   to read and save error tracking data.
      #
      # * When integrated error tracking is disabled we call
      #   project_error_tracking_setting method which works with Sentry API.
      #
      # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/329596
      #
      if project_error_tracking_setting.integrated_client?
        updated = error_repository.update_error(opts[:issue_id], status: opts[:params][:status])

        # We use the same response format as project_error_tracking_setting
        # method below for compatibility with existing code.
        {
          updated: updated
        }
      else
        project_error_tracking_setting.update_issue(**opts)
      end
    end
  end
end
