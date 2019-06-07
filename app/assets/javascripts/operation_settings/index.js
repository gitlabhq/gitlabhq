import Vue from 'vue';
import store from './store';
import ExternalDashboardForm from './components/external_dashboard.vue';

export default () => {
  /**
   * This check can be removed when we remove
   * the :grafana_dashboard_link feature flag
   */
  if (!gon.features.grafanaDashboardLink) {
    return null;
  }

  const el = document.querySelector('.js-operation-settings');

  return new Vue({
    el,
    store: store(el.dataset),
    render(createElement) {
      return createElement(ExternalDashboardForm);
    },
  });
};
