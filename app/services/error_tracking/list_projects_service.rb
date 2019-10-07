# frozen_string_literal: true

module ErrorTracking
  class ListProjectsService < ::BaseService
    def execute
      return error('access denied') unless can_read?

      setting = project_error_tracking_setting

      unless setting.valid?
        return error(setting.errors.full_messages.join(', '), :bad_request)
      end

      begin
        result = setting.list_sentry_projects
      rescue Sentry::Client::Error => e
        return error(e.message, :bad_request)
      rescue Sentry::Client::MissingKeysError => e
        return error(e.message, :internal_server_error)
      end

      success(projects: result[:projects])
    end

    private

    def project_error_tracking_setting
      (project.error_tracking_setting || project.build_error_tracking_setting).tap do |setting|
        setting.api_url = ErrorTracking::ProjectErrorTrackingSetting.build_api_url_from(
          api_host: params[:api_host],
          organization_slug: 'org',
          project_slug: 'proj'
        )

        setting.token = token(setting)
        setting.enabled = true
      end
    end

    def can_read?
      can?(current_user, :read_sentry_issue, project)
    end

    def token(setting)
      # Use param token if not masked, otherwise use database token
      return params[:token] unless /\A\*+\z/.match?(params[:token])

      setting.token
    end
  end
end
