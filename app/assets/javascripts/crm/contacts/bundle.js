import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CrmContactsApp from './contacts_app.vue';
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
    groupWorkItemsPath,
    groupOrganizationsPath,
    canAdminCrmContact,
    canReadCrmOrganization,
    groupId,
    textQuery,
  } = el.dataset;

  const router = new VueRouter({
    base: basePath,
    mode: 'history',
    routes,
  });

  return initVueApp({
    el,
    name: 'CrmContactsAppRoot',
    router,
    apolloProvider,
    provide: {
      groupFullPath,
      groupWorkItemsPath,
      groupOrganizationsPath,
      canAdminCrmContact: parseBoolean(canAdminCrmContact),
      canReadCrmOrganization: parseBoolean(canReadCrmOrganization),
      groupId,
      textQuery,
    },
    component: CrmContactsApp,
  });
};
