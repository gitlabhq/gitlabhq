import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import AddOrganizationUsersTrigger from './components/add_organization_users_trigger.vue';

export const initAdminAddOrganizationUsers = () => {
  const el = document.getElementById('js-admin-add-organization-users');

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { organizationGid, organizationName, searchUrl, buttonVariant } =
    convertObjectPropsToCamelCase(JSON.parse(el.dataset.appData));

  return initVueApp({
    el,
    name: 'AdminAddOrganizationUsersRoot',
    apolloProvider,
    provide: {
      organizationGid,
      organizationName,
      searchUrl,
    },
    component: AddOrganizationUsersTrigger,
    props: {
      buttonVariant,
    },
  });
};
