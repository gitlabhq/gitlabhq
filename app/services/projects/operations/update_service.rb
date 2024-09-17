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
          .merge(alerting_setting_params)
          .merge(prometheus_integration_params)
          .merge(incident_management_setting_params)
      end

      def alerting_setting_params
        return {} unless can?(current_user, :admin_operations, project)

        attr = params[:alerting_setting_attributes]
        return {} unless attr

        regenerate_token = attr.delete(:regenerate_token)

        if regenerate_token
          attr[:token] = nil
        else
          attr = attr.except(:token)
        end

        { alerting_setting_attributes: attr }
      end

      def error_tracking_params
        settings = params[:error_tracking_setting_attributes]
        return {} if settings.blank?

        if error_tracking_params_partial_updates?(settings)
          error_tracking_params_for_partial_update(settings)
        else
          error_tracking_params_for_update(settings)
        end
      end

      def error_tracking_params_partial_updates?(settings)
        # Help from @splattael :bow:
        # Make sure we're converting to symbols because
        # * ActionController::Parameters#keys returns a list of strings
        # * in specs we're using hashes with symbols as keys
        update_keys = settings.keys.map(&:to_sym)

        # Integrated error tracking works without Sentry integration,
        # so we don't need to update all those values from error_tracking_params_for_update method.
        # Instead we turn it on/off with partial update together with "enabled" attribute.
        # But since its optional, we exclude it from the condition below.
        update_keys.delete(:integrated)

        update_keys == %i[enabled]
      end

      def error_tracking_params_for_partial_update(settings)
        { error_tracking_setting_attributes: settings }
      end

      def error_tracking_params_for_update(settings)
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
            organization_name: settings.dig(:project, :organization_name),
            sentry_project_id: settings.dig(:project, :sentry_project_id)
          }
        }
        params[:error_tracking_setting_attributes][:token] = settings[:token] unless ::ErrorTracking::SentryClient::Token.masked_token?(settings[:token]) # Don't update token if we receive masked value
        params[:error_tracking_setting_attributes][:integrated] = settings[:integrated] unless settings[:integrated].nil?

        params
      end

      def prometheus_integration_params
        return {} unless attrs = params[:prometheus_integration_attributes]

        integration = project.find_or_initialize_integration(::Integrations::Prometheus.to_param)
        integration.assign_attributes(attrs)
        attrs = integration.to_database_hash

        { prometheus_integration_attributes: attrs }
      end

      def incident_management_setting_params
        attrs = params[:incident_management_setting_attributes]
        return {} unless attrs

        regenerate_token = attrs.delete(:regenerate_token)

        if regenerate_token
          attrs[:pagerduty_token] = nil
        else
          attrs = attrs.except(:pagerduty_token)
        end

        { incident_management_setting_attributes: attrs }
      end
    end
  end
end

Projects::Operations::UpdateService.prepend_mod_with('Projects::Operations::UpdateService')
