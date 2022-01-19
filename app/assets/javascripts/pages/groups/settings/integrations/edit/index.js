import initIntegrationSettingsForm from '~/integrations/edit';
import PrometheusMetrics from '~/prometheus_metrics/prometheus_metrics';

initIntegrationSettingsForm();

const prometheusSettingsSelector = '.js-prometheus-metrics-monitoring';
const prometheusSettingsWrapper = document.querySelector(prometheusSettingsSelector);
if (prometheusSettingsWrapper) {
  const prometheusMetrics = new PrometheusMetrics(prometheusSettingsSelector);
  prometheusMetrics.loadActiveMetrics();
}
