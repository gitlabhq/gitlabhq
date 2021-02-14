import Vue from 'vue';
import MetricsSettingsForm from './components/metrics_settings.vue';
import store from './store';

export default () => {
  const el = document.querySelector('.js-operation-settings');

  return new Vue({
    el,
    store: store(el.dataset),
    render(createElement) {
      return createElement(MetricsSettingsForm);
    },
  });
};
