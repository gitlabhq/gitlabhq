# frozen_string_literal: true

module ErrorTracking
  class ListIssuesService < ::BaseService
    DEFAULT_ISSUE_STATUS = 'unresolved'
    DEFAULT_LIMIT = 20

    def execute
      return error('not enabled') unless enabled?
      return error('access denied') unless can_read?

      result = project_error_tracking_setting
        .list_sentry_issues(issue_status: issue_status, limit: limit)

      # our results are not yet ready
      unless result
        return error('not ready', :no_content)
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
