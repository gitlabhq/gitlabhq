# frozen_string_literal: true

module ErrorTracking
  class IssueLatestEventService < ErrorTracking::BaseService
    private

    def perform
      response = project_error_tracking_setting.issue_latest_event(issue_id: params[:issue_id])

      compose_response(response)
    end

    def parse_response(response)
      { latest_event: response[:latest_event] }
    end
  end
end
