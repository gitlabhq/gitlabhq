import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

export const initOrganizationsNew = () => {
  const el = document.getElementById('js-organizations-new');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { organizationsPath, rootUrl, previewMarkdownPath } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
  );

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'OrganizationNewRoot',
    apolloProvider,
    provide: {
      organizationsPath,
      rootUrl,
      previewMarkdownPath,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
