# frozen_string_literal: true

module ErrorTracking
  class IssueUpdateService < ErrorTracking::BaseService
    private

    def fetch
      project_error_tracking_setting.update_issue(
        issue_id: params[:issue_id],
        params: update_params
      )
    end

    def update_params
      params.except(:issue_id)
    end

    def parse_response(response)
      { updated: response[:updated].present? }
    end
  end
end
