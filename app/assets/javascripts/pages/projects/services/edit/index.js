import initIntegrationSettingsForm from '~/integrations/edit';
import PrometheusAlerts from '~/prometheus_alerts';
import CustomMetrics from '~/prometheus_metrics/custom_metrics';

initIntegrationSettingsForm();

const prometheusSettingsSelector = '.js-prometheus-metrics-monitoring';
const prometheusSettingsWrapper = document.querySelector(prometheusSettingsSelector);
if (prometheusSettingsWrapper) {
  const customMetrics = new CustomMetrics(prometheusSettingsSelector);
  customMetrics.init();
}

PrometheusAlerts();
