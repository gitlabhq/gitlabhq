import Vue from 'vue';
import GrafanaIntegration from './components/grafana_integration.vue';
import store from './store';

export default () => {
  const el = document.querySelector('.js-grafana-integration');

  if (!el) return false;

  return new Vue({
    el,
    store: store(el.dataset),
    render(createElement) {
      return createElement(GrafanaIntegration);
    },
  });
};
