import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import OrganizationsUsersApp from './components/app.vue';

export const initOrganizationsUsers = () => {
  Vue.use(GlToast);

  const el = document.getElementById('js-organizations-users');

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { organizationGid, paths } = convertObjectPropsToCamelCase(JSON.parse(el.dataset.appData), {
    deep: true,
  });

  return new Vue({
    el,
    name: 'OrganizationsUsersRoot',
    apolloProvider,
    provide: {
      organizationGid,
      paths,
    },
    render(createElement) {
      return createElement(OrganizationsUsersApp);
    },
  });
};
