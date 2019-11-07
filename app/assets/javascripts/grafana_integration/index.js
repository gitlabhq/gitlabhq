import Vue from 'vue';
import store from './store';
import GrafanaIntegration from './components/grafana_integration.vue';

export default () => {
  const el = document.querySelector('.js-grafana-integration');
  return new Vue({
    el,
    store: store(el.dataset),
    render(createElement) {
      return createElement(GrafanaIntegration);
    },
  });
};
