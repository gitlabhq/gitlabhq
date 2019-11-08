# frozen_string_literal: true

module ErrorTracking
  class ListProjectsService < ErrorTracking::BaseService
    def execute
      unless project_error_tracking_setting.valid?
        return error(project_error_tracking_setting.errors.full_messages.join(', '), :bad_request)
      end

      super
    end

    private

    def fetch
      project_error_tracking_setting.list_sentry_projects
    end

    def parse_response(response)
      { projects: response[:projects] }
    end

    def project_error_tracking_setting
      @project_error_tracking_setting ||= begin
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
    end

    def token(setting)
      # Use param token if not masked, otherwise use database token
      return params[:token] unless /\A\*+\z/.match?(params[:token])

      setting.token
    end
  end
end
