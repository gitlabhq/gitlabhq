# frozen_string_literal: true

module ErrorTracking
  class ListProjectsService < ErrorTracking::BaseService
    private

    def perform
      return error('Access denied', :unauthorized) unless can?(current_user, :admin_sentry, project)

      unless project_error_tracking_setting.valid?
        return error(project_error_tracking_setting.errors.full_messages.join(', '), :bad_request)
      end

      response = project_error_tracking_setting.list_sentry_projects

      compose_response(response)
    end

    def parse_response(response)
      { projects: response[:projects] }
    end

    def project_error_tracking_setting
      (super || project.build_error_tracking_setting).tap do |setting|
        setting.api_url = ErrorTracking::ProjectErrorTrackingSetting.build_api_url_from(
          api_host: params[:api_host],
          organization_slug: 'org',
          project_slug: 'proj'
        )

        setting.token = token(setting)
        setting.enabled = true
      end
    end
    strong_memoize_attr :project_error_tracking_setting

    def token(setting)
      return if setting.api_url_changed? && masked_token?

      # Use param token if not masked, otherwise use database token
      return params[:token] unless masked_token?

      setting.token
    end

    def masked_token?
      ErrorTracking::SentryClient::Token.masked_token?(params[:token])
    end
  end
end
