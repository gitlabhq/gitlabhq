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
        error_tracking_params
          .merge(metrics_setting_params)
          .merge(grafana_integration_params)
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

        api_url = ::ErrorTracking::ProjectErrorTrackingSetting.build_api_url_from(
          api_host: settings[:api_host],
          project_slug: settings.dig(:project, :slug),
          organization_slug: settings.dig(:project, :organization_slug)
        )

        params = {
          error_tracking_setting_attributes: {
            api_url: api_url,
            enabled: settings[:enabled],
            project_name: settings.dig(:project, :name),
            organization_name: settings.dig(:project, :organization_name)
          }
        }
        params[:error_tracking_setting_attributes][:token] = settings[:token] unless /\A\*+\z/.match?(settings[:token]) # Don't update token if we receive masked value

        params
      end

      def grafana_integration_params
        return {} unless attrs = params[:grafana_integration_attributes]

        destroy = attrs[:grafana_url].blank? && attrs[:token].blank?

        { grafana_integration_attributes: attrs.merge(_destroy: destroy) }
      end
    end
  end
end

Projects::Operations::UpdateService.prepend_if_ee('::EE::Projects::Operations::UpdateService')
