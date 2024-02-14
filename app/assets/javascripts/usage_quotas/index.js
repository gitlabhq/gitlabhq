import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import {
  usageQuotasTabsMetadata,
  usageQuotasViewProvideData,
} from 'ee_else_ce/usage_quotas/group_view_metadata';
import UsageQuotasApp from './components/usage_quotas_app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-usage-quotas-view');

  if (!el) {
    return false;
  }

  const { namespaceName } = el.dataset;

  return new Vue({
    el,
    name: 'UsageQuotasView',
    apolloProvider,
    provide: {
      namespaceName,
      tabs: usageQuotasTabsMetadata,
      ...usageQuotasViewProvideData,
    },
    render(createElement) {
      return createElement(UsageQuotasApp);
    },
  });
};
