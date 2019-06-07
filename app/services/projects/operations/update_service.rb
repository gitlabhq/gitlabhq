# frozen_string_literal: true

module Projects
  module Operations
    class UpdateService < BaseService
      def execute
        Projects::UpdateService
          .new(project, current_user, project_update_params)
          .execute
      end

      private

      def project_update_params
        error_tracking_params.merge(metrics_setting_params)
      end

      def metrics_setting_params
        attribs = params[:metrics_setting_attributes]
        return {} unless attribs

        destroy = attribs[:external_dashboard_url].blank?

        { metrics_setting_attributes: attribs.merge(_destroy: destroy) }
      end

      def error_tracking_params
        settings = params[:error_tracking_setting_attributes]
        return {} if settings.blank?

        api_url = ErrorTracking::ProjectErrorTrackingSetting.build_api_url_from(
          api_host: settings[:api_host],
          project_slug: settings.dig(:project, :slug),
          organization_slug: settings.dig(:project, :organization_slug)
        )

        {
          error_tracking_setting_attributes: {
            api_url: api_url,
            token: settings[:token],
            enabled: settings[:enabled],
            project_name: settings.dig(:project, :name),
            organization_name: settings.dig(:project, :organization_name)
          }
        }
      end
    end
  end
end
