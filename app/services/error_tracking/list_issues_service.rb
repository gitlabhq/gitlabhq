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

      sentry_opts = {
        issue_status: issue_status,
        limit: limit,
        search_term: params[:search_term].presence,
        sort: sort,
        cursor: params[:cursor].presence
      }

      response = list_issues(sentry_opts)

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

    def list_issues(opts)
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
        # We are going to support more options in the future.
        # For now we implement the bare minimum for rendering the list in UI.
        filter_opts = {
          status: opts[:issue_status]
        }

        errors = ErrorTracking::ErrorsFinder.new(current_user, project, filter_opts).execute

        # We use the same response format as project_error_tracking_setting
        # method below for compatibility with existing code.
        {
          issues: errors.map(&:to_sentry_error),
          pagination: {}
        }
      else
        project_error_tracking_setting.list_sentry_issues(**opts)
      end
    end
  end
end
