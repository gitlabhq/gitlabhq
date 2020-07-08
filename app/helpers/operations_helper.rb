# frozen_string_literal: true

module OperationsHelper
  include Gitlab::Utils::StrongMemoize

  def prometheus_service
    strong_memoize(:prometheus_service) do
      @project.find_or_initialize_service(::PrometheusService.to_param)
    end
  end

  def alerts_service
    strong_memoize(:alerts_service) do
      @project.find_or_initialize_service(::AlertsService.to_param)
    end
  end

  def alerts_settings_data
    {
      'prometheus_activated' => prometheus_service.manual_configuration?.to_s,
      'activated' => alerts_service.activated?.to_s,
      'prometheus_form_path' => scoped_integration_path(prometheus_service),
      'form_path' => scoped_integration_path(alerts_service),
      'prometheus_reset_key_path' => reset_alerting_token_project_settings_operations_path(@project),
      'prometheus_authorization_key' => @project.alerting_setting&.token,
      'prometheus_api_url' => prometheus_service.api_url,
      'authorization_key' => alerts_service.token,
      'prometheus_url' => notify_project_prometheus_alerts_url(@project, format: :json),
      'url' => alerts_service.url,
      'alerts_setup_url' => help_page_path('user/project/integrations/generic_alerts.md', anchor: 'setting-up-generic-alerts'),
      'alerts_usage_url' => project_alert_management_index_path(@project)
    }
  end
end

OperationsHelper.prepend_if_ee('EE::OperationsHelper')
