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

  def alerts_settings_data(disabled: false)
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
      'alerts_setup_url' => help_page_path('operations/incident_management/alert_integrations.md', anchor: 'generic-http-endpoint'),
      'alerts_usage_url' => project_alert_management_index_path(@project),
      'disabled' => disabled.to_s,
      'project_path' => @project.full_path,
      'multi_integrations' => 'false'
    }
  end

  def operations_settings_data
    setting = project_incident_management_setting
    templates = setting.available_issue_templates.map { |t| { key: t.key, name: t.name } }

    {
      operations_settings_endpoint: project_settings_operations_path(@project),
      templates: templates.to_json,
      create_issue: setting.create_issue.to_s,
      issue_template_key: setting.issue_template_key.to_s,
      send_email: setting.send_email.to_s,
      auto_close_incident: setting.auto_close_incident.to_s,
      pagerduty_active: setting.pagerduty_active.to_s,
      pagerduty_token: setting.pagerduty_token.to_s,
      pagerduty_webhook_url: project_incidents_integrations_pagerduty_url(@project, token: setting.pagerduty_token),
      pagerduty_reset_key_path: reset_pagerduty_token_project_settings_operations_path(@project)
    }
  end
end

OperationsHelper.prepend_if_ee('EE::OperationsHelper')
