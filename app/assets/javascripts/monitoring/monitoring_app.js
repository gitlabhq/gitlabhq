import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { createStore } from './stores';
import createRouter from './router';
import { stateAndPropsFromDataset } from './utils';

Vue.use(GlToast);

export default (props = {}) => {
  const el = document.getElementById('prometheus-graphs');

  if (el && el.dataset) {
    const { metricsDashboardBasePath, ...dataset } = el.dataset;

    const { initState, dataProps } = stateAndPropsFromDataset(dataset);
    const store = createStore(initState);
    const router = createRouter(metricsDashboardBasePath);

    // eslint-disable-next-line no-new
    new Vue({
      el,
      store,
      router,
      data() {
        return {
          dashboardProps: { ...dataProps, ...props },
        };
      },
      template: `<router-view :dashboardProps="dashboardProps"/>`,
    });
  }
};
