import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CrmOrganizationsRoot from './components/organizations_root.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-crm-organizations-app');

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  if (!el) {
    return false;
  }

  const { groupFullPath, groupIssuesPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: { groupFullPath, groupIssuesPath },
    render(createElement) {
      return createElement(CrmOrganizationsRoot);
    },
  });
};
