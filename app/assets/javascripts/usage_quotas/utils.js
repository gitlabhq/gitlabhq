import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import UsageQuotasApp from './components/usage_quotas_app.vue';

export const mountUsageQuotasApp = (tabs) => {
  const el = document.querySelector('#js-usage-quotas-view');

  if (!el || !tabs) return false;

  return initVueApp({
    el,
    name: 'UsageQuotasView',
    provide: {
      tabs,
    },
    component: UsageQuotasApp,
  });
};
