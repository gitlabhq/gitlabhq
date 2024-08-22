import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

export const initOrganizationsSettingsGeneral = () => {
  const el = document.getElementById('js-organizations-settings-general');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { organization, organizationsPath, rootUrl, previewMarkdownPath } =
    convertObjectPropsToCamelCase(JSON.parse(appData), { deep: true });

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'OrganizationSettingsGeneralRoot',
    apolloProvider,
    provide: {
      organization,
      organizationsPath,
      rootUrl,
      previewMarkdownPath,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
