import Vue from 'vue';
import Dashboard from '~/monitoring/components/dashboard.vue';

export default () => {
  const el = document.querySelector('#prometheus-graphs');

  if (el) {
    // eslint-disable-next-line no-new
    new Vue({
      el,
      render: createElement => createElement(Dashboard),
    });
  }
};
