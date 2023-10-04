import Vue from 'vue';

import GlobalAlerts from './components/global_alerts.vue';

export const initGlobalAlerts = () => {
  const el = document.getElementById('js-global-alerts');

  if (!el) return false;

  return new Vue({
    el,
    name: 'GlobalAlertsRoot',
    render(createElement) {
      return createElement(GlobalAlerts);
    },
  });
};
