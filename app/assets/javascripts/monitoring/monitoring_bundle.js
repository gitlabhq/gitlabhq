import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { getParameterValues } from '~/lib/utils/url_utility';
import Dashboard from 'ee_else_ce/monitoring/components/dashboard.vue';
import store from './stores';

export default (props = {}) => {
  const el = document.getElementById('prometheus-graphs');

  if (el && el.dataset) {
    if (gon.features) {
      store.dispatch('monitoringDashboard/setFeatureFlags', {
        prometheusEndpointEnabled: gon.features.environmentMetricsUsePrometheusEndpoint,
        multipleDashboardsEnabled: gon.features.environmentMetricsShowMultipleDashboards,
        additionalPanelTypesEnabled: gon.features.environmentMetricsAdditionalPanelTypes,
        exportMetricsToCsvEnabled: gon.features.exportMetricsToCsvEnabled,
      });
    }

    const [currentDashboard] = getParameterValues('dashboard');

    // eslint-disable-next-line no-new
    new Vue({
      el,
      store,
      render(createElement) {
        return createElement(Dashboard, {
          props: {
            ...el.dataset,
            currentDashboard,
            hasMetrics: parseBoolean(el.dataset.hasMetrics),
            ...props,
          },
        });
      },
    });
  }
};
