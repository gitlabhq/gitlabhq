import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import OrganizationsUsersApp from './components/app.vue';

export const initOrganizationsUsers = () => {
  const el = document.getElementById('js-organizations-users');

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { organizationGid } = convertObjectPropsToCamelCase(el.dataset);

  return new Vue({
    el,
    name: 'OrganizationsUsersRoot',
    apolloProvider,
    provide: {
      organizationGid,
    },
    render(createElement) {
      return createElement(OrganizationsUsersApp);
    },
  });
};
