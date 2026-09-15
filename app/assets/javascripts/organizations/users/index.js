import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import OrganizationsUsersApp from './components/app.vue';

export const initOrganizationsUsers = () => {
  const el = document.getElementById('js-organizations-users');

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { organizationGid, paths } = convertObjectPropsToCamelCase(JSON.parse(el.dataset.appData), {
    deep: true,
  });

  return initVueApp({
    el,
    name: 'OrganizationsUsersRoot',
    apolloProvider,
    provide: {
      organizationGid,
      paths,
    },
    component: OrganizationsUsersApp,
  });
};
