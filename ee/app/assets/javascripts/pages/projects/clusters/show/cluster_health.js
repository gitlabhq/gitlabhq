import Vue from 'vue';
import Dashboard from '~/monitoring/components/dashboard.vue';

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
            showLegend: false,
            showPanels: false,
            forceSmallGraph: true,
          },
        });
      },
    });
  }
};
