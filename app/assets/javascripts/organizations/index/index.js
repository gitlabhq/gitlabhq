import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import OrganizationsIndexApp from './components/app.vue';

export const initOrganizationsIndex = () => {
  const el = document.getElementById('js-organizations-index');

  if (!el) return false;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    dataset: { appData },
  } = el;
  const { newOrganizationUrl, canCreateOrganization } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
  );

  return new Vue({
    el,
    name: 'OrganizationsIndexRoot',
    apolloProvider,
    provide: {
      newOrganizationUrl,
      canCreateOrganization,
    },
    render(createElement) {
      return createElement(OrganizationsIndexApp);
    },
  });
};
