import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { getParameterValues } from '~/lib/utils/url_utility';
import store from './stores';
import { promCustomVariablesFromUrl } from './utils';

Vue.use(GlToast);

export default (props = {}) => {
  const el = document.getElementById('prometheus-graphs');

  if (el && el.dataset) {
    const [currentDashboard] = getParameterValues('dashboard');

    store.dispatch('monitoringDashboard/setVariables', promCustomVariablesFromUrl());

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
