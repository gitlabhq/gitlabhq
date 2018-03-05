import IntegrationSettingsForm from '~/integrations/integration_settings_form';
import PrometheusMetrics from 'ee/prometheus_metrics/prometheus_metrics';

document.addEventListener('DOMContentLoaded', () => {
  const integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
  integrationSettingsForm.init();

  const prometheusSettingsWrapper = document.querySelector('.js-prometheus-metrics-monitoring');
  if (prometheusSettingsWrapper) {
    const prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    prometheusMetrics.loadActiveCustomMetrics();
  }
});
