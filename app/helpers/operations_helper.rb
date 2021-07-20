# frozen_string_literal: true

module OperationsHelper
  include Gitlab::Utils::StrongMemoize
  include IntegrationsHelper

  def prometheus_integration
    strong_memoize(:prometheus_integration) do
      @project.find_or_initialize_integration(::Integrations::Prometheus.to_param)
    end
  end

  def alerts_settings_data(disabled: false)
    setting = project_incident_management_setting
    templates = setting.available_issue_templates.map { |t| { key: t.key, name: t.name } }

    {
      'prometheus_activated' => prometheus_integration.manual_configuration?.to_s,
      'prometheus_form_path' => scoped_integration_path(prometheus_integration),
      'prometheus_reset_key_path' => reset_alerting_token_project_settings_operations_path(@project),
      'prometheus_authorization_key' => @project.alerting_setting&.token,
      'prometheus_api_url' => prometheus_integration.api_url,
      'prometheus_url' => notify_project_prometheus_alerts_url(@project, format: :json),
      'alerts_setup_url' => help_page_path('operations/incident_management/integrations.md', anchor: 'configuration'),
      'alerts_usage_url' => project_alert_management_index_path(@project),
      'disabled' => disabled.to_s,
      'project_path' => @project.full_path,
      'multi_integrations' => 'false',
      'templates' => templates.to_json,
      'create_issue' => setting.create_issue.to_s,
      'issue_template_key' => setting.issue_template_key.to_s,
      'send_email' => setting.send_email.to_s,
      'auto_close_incident' => setting.auto_close_incident.to_s,
      'pagerduty_reset_key_path' => reset_pagerduty_token_project_settings_operations_path(@project),
      'operations_settings_endpoint' => project_settings_operations_path(@project)
    }
  end

  def operations_settings_data
    setting = project_incident_management_setting

    {
      operations_settings_endpoint: project_settings_operations_path(@project),
      pagerduty_active: setting.pagerduty_active.to_s,
      pagerduty_token: setting.pagerduty_token.to_s,
      pagerduty_webhook_url: project_incidents_integrations_pagerduty_url(@project, token: setting.pagerduty_token),
      pagerduty_reset_key_path: reset_pagerduty_token_project_settings_operations_path(@project)
    }
  end
end

OperationsHelper.prepend_mod_with('OperationsHelper')
