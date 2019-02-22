# frozen_string_literal: true

module ErrorTracking
  class ListIssuesService < ::BaseService
    DEFAULT_ISSUE_STATUS = 'unresolved'
    DEFAULT_LIMIT = 20

    def execute
      return error('Error Tracking is not enabled') unless enabled?
      return error('Access denied', :unauthorized) unless can_read?

      result = project_error_tracking_setting
        .list_sentry_issues(issue_status: issue_status, limit: limit)

      # our results are not yet ready
      unless result
        return error('Not ready. Try again later', :no_content)
      end

      if result[:error].present?
        return error(result[:error], :bad_request)
      end

      success(issues: result[:issues])
    end

    def external_url
      project_error_tracking_setting&.sentry_external_url
    end

    private

    def project_error_tracking_setting
      project.error_tracking_setting
    end

    def issue_status
      params[:issue_status] || DEFAULT_ISSUE_STATUS
    end

    def limit
      params[:limit] || DEFAULT_LIMIT
    end

    def enabled?
      project_error_tracking_setting&.enabled?
    end

    def can_read?
      can?(current_user, :read_sentry_issue, project)
    end
  end
end
