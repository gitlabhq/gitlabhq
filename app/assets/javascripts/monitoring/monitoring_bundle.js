import Vue from 'vue';
import { convertPermissionToBoolean } from '~/lib/utils/common_utils';
import Dashboard from './components/dashboard.vue';

export default () => {
  const el = document.getElementById('prometheus-graphs');

  if (el && el.dataset) {
    // eslint-disable-next-line no-new
    new Vue({
      el,
      render(createElement) {
        return createElement(Dashboard, {
          props: {
            ...el.dataset,
            hasMetrics: convertPermissionToBoolean(el.dataset.hasMetrics),
          },
        });
      },
    });
  }
};
