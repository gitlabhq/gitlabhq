# frozen_string_literal: true

module ErrorTracking
  class ListIssuesService < ErrorTracking::BaseService
    DEFAULT_ISSUE_STATUS = 'unresolved'
    DEFAULT_LIMIT = 20
    DEFAULT_SORT = 'last_seen'

    # Sentry client supports 'muted' and 'assigned' but GitLab does not
    ISSUE_STATUS_VALUES = %w[
      resolved
      unresolved
      ignored
    ].freeze

    def external_url
      project_error_tracking_setting&.sentry_external_url
    end

    private

    def perform
      return invalid_status_error unless valid_status?

      response = project_error_tracking_setting.list_sentry_issues(
        issue_status: issue_status,
        limit: limit,
        search_term: params[:search_term].presence,
        sort: sort,
        cursor: params[:cursor].presence
      )

      compose_response(response)
    end

    def parse_response(response)
      response.slice(:issues, :pagination)
    end

    def invalid_status_error
      error('Bad Request: Invalid issue_status', http_status_for(:bad_Request))
    end

    def valid_status?
      ISSUE_STATUS_VALUES.include?(issue_status)
    end

    def issue_status
      params[:issue_status] || DEFAULT_ISSUE_STATUS
    end

    def limit
      params[:limit] || DEFAULT_LIMIT
    end

    def sort
      params[:sort] || DEFAULT_SORT
    end
  end
end
