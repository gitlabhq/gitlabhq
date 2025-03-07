import Vue from 'vue';
import UsageQuotasApp from './components/usage_quotas_app.vue';

export const mountUsageQuotasApp = (tabs) => {
  const el = document.querySelector('#js-usage-quotas-view');

  if (!el || !tabs) return false;

  return new Vue({
    el,
    name: 'UsageQuotasView',
    provide: {
      tabs,
    },
    render(createElement) {
      return createElement(UsageQuotasApp);
    },
  });
};
