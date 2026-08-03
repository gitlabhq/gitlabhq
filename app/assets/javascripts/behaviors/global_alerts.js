import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

import GlobalAlerts from './components/global_alerts.vue';

export const initGlobalAlerts = () => {
  const el = document.getElementById('js-global-alerts');

  if (!el) return false;

  return initVueApp({ el, name: 'GlobalAlertsRoot', component: GlobalAlerts });
};
