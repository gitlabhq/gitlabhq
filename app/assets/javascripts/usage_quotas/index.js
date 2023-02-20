import Vue from 'vue';
import UsageQuotasApp from './components/usage_quotas_app.vue';

export default () => {
  const el = document.getElementById('js-usage-quotas-view');

  if (!el) {
    return false;
  }

  const { namespaceName } = el.dataset;

  return new Vue({
    el,
    name: 'UsageQuotasView',
    provide: {
      namespaceName,
    },
    render(createElement) {
      return createElement(UsageQuotasApp);
    },
  });
};
