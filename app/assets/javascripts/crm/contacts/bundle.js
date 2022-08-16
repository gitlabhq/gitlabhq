import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CrmContactsRoot from './components/contacts_root.vue';
import routes from './routes';

Vue.use(VueApollo);
Vue.use(VueRouter);
Vue.use(GlToast);

export default () => {
  const el = document.getElementById('js-crm-contacts-app');

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  if (!el) {
    return false;
  }

  const {
    basePath,
    groupFullPath,
    groupIssuesPath,
    canAdminCrmContact,
    groupId,
    textQuery,
  } = el.dataset;

  const router = new VueRouter({
    base: basePath,
    mode: 'history',
    routes,
  });

  return new Vue({
    el,
    router,
    apolloProvider,
    provide: {
      groupFullPath,
      groupIssuesPath,
      canAdminCrmContact: parseBoolean(canAdminCrmContact),
      groupId,
      textQuery,
    },
    render(createElement) {
      return createElement(CrmContactsRoot);
    },
  });
};
