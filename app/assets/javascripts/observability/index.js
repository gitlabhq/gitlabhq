import Vue from 'vue';
import VueRouter from 'vue-router';

import ObservabilityApp from './components/observability_app.vue';

Vue.use(VueRouter);

export default () => {
  const el = document.getElementById('js-observability-app');

  if (!el) return false;

  const router = new VueRouter({
    mode: 'history',
  });

  return new Vue({
    el,
    router,
    render(h) {
      return h(ObservabilityApp, {
        props: {
          observabilityIframeSrc: el.dataset.observabilityIframeSrc,
        },
      });
    },
  });
};
