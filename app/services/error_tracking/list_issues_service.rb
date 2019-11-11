# frozen_string_literal: true

module ErrorTracking
  class ListIssuesService < ErrorTracking::BaseService
    DEFAULT_ISSUE_STATUS = 'unresolved'
    DEFAULT_LIMIT = 20

    def external_url
      project_error_tracking_setting&.sentry_external_url
    end

    private

    def fetch
      project_error_tracking_setting.list_sentry_issues(issue_status: issue_status, limit: limit)
    end

    def parse_response(response)
      { issues: response[:issues] }
    end

    def issue_status
      params[:issue_status] || DEFAULT_ISSUE_STATUS
    end

    def limit
      params[:limit] || DEFAULT_LIMIT
    end
  end
end
