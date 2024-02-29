import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { usageQuotasTabsMetadata } from 'ee_else_ce/usage_quotas/group_view_metadata';
import UsageQuotasApp from './components/usage_quotas_app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-usage-quotas-view');

  if (!el) return false;

  return new Vue({
    el,
    name: 'UsageQuotasView',
    apolloProvider,
    provide: {
      tabs: usageQuotasTabsMetadata.filter(Boolean),
    },
    render(createElement) {
      return createElement(UsageQuotasApp);
    },
  });
};
