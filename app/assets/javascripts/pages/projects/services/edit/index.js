import IntegrationSettingsForm from '~/integrations/integration_settings_form';
import PrometheusAlerts from '~/prometheus_alerts';
import CustomMetrics from '~/prometheus_metrics/custom_metrics';

document.addEventListener('DOMContentLoaded', () => {
  const integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
  integrationSettingsForm.init();

  const prometheusSettingsSelector = '.js-prometheus-metrics-monitoring';
  const prometheusSettingsWrapper = document.querySelector(prometheusSettingsSelector);
  if (prometheusSettingsWrapper) {
    const customMetrics = new CustomMetrics(prometheusSettingsSelector);
    customMetrics.init();
  }

  PrometheusAlerts();
});
