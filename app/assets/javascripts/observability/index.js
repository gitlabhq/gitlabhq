import Vue from 'vue';
import ObservabilityApp from './components/app.vue';

export default () => {
  const el = document.getElementById('js-observability');
  if (!el) return null;
  const { dataset } = el;

  return new Vue({
    el,
    render(h) {
      return h(ObservabilityApp, {
        props: {
          o11yUrl: dataset.o11yUrl,
          path: dataset.path,
        },
      });
    },
  });
};
