import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

export const initAdminOrganizationsIndex = () => {
  const el = document.getElementById('js-admin-organizations-index');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { newOrganizationUrl, canCreateOrganization } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
  );

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'AdminOrganizationIndexRoot',
    apolloProvider,
    provide: {
      newOrganizationUrl,
      canCreateOrganization,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
