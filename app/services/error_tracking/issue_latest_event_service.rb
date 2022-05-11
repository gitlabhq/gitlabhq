# frozen_string_literal: true

module ErrorTracking
  class IssueLatestEventService < ErrorTracking::BaseService
    private

    def perform
      response = find_issue_latest_event(params[:issue_id])

      compose_response(response)
    end

    def parse_response(response)
      { latest_event: response[:latest_event] }
    end

    def find_issue_latest_event(issue_id)
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
        handle_error_repository_exceptions do
          event = error_repository.last_event_for(issue_id)

          # We use the same response format as project_error_tracking_setting
          # method below for compatibility with existing code.
          { latest_event: event }
        end
      else
        project_error_tracking_setting.issue_latest_event(issue_id: issue_id)
      end
    end
  end
end
