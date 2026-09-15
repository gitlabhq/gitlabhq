import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import App from './components/app.vue';

export const initOrganizationsShow = () => {
  const el = document.getElementById('js-organizations-show');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { organization, canAdminOrganization, canLeaveOrganization, organizationUserGid } =
    convertObjectPropsToCamelCase(JSON.parse(appData));

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'OrganizationShowRoot',
    apolloProvider,
    component: App,
    props: {
      organization,
      canAdminOrganization,
      canLeaveOrganization,
      organizationUserGid,
    },
  });
};
