import PrometheusMetrics from './prometheus_metrics';

$(() => {
  const prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
  prometheusMetrics.loadActiveMetrics();
});
