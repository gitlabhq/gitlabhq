import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import Dashboard from 'ee_else_ce/monitoring/components/dashboard.vue';
import store from './stores';

export default (props = {}) => {
  const el = document.getElementById('prometheus-graphs');

  if (el && el.dataset) {
    store.dispatch(
      'monitoringDashboard/setDashboardEnabled',
      gon.features.environmentMetricsUsePrometheusEndpoint,
    );

    // eslint-disable-next-line no-new
    new Vue({
      el,
      store,
      render(createElement) {
        return createElement(Dashboard, {
          props: {
            ...el.dataset,
            hasMetrics: parseBoolean(el.dataset.hasMetrics),
            showTimeWindowDropdown: gon.features.metricsTimeWindow,
            ...props,
          },
        });
      },
    });
  }
};
