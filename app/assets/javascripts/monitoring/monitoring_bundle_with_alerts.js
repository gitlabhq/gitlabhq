import { parseBoolean } from '~/lib/utils/common_utils';
import initCeBundle from '~/monitoring/monitoring_bundle';

export default () => {
  const el = document.getElementById('prometheus-graphs');

  if (el && el.dataset) {
    initCeBundle({
      customMetricsAvailable: parseBoolean(el.dataset.customMetricsAvailable),
      prometheusAlertsAvailable: parseBoolean(el.dataset.prometheusAlertsAvailable),
    });
  }
};
