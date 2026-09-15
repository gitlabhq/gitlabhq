import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import App from 'ee_else_ce/organizations/settings/general/components/app.vue';

export const initOrganizationsSettingsGeneral = () => {
  const el = document.getElementById('js-organizations-settings-general');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const {
    organization,
    maxGroupVisibilityLevel,
    organizationsUrl,
    previewMarkdownPath,
    // EE-only keys, absent (undefined) in CE app data.
    policyStoreExperimentAvailable,
    policyStoreExperimentEnabled,
  } = convertObjectPropsToCamelCase(JSON.parse(appData), { deep: true });

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'OrganizationSettingsGeneralRoot',
    apolloProvider,
    provide: {
      organization,
      organizationsUrl,
      previewMarkdownPath,
      maxGroupVisibilityLevel,
      policyStoreExperimentAvailable,
      policyStoreExperimentEnabled,
    },
    component: App,
  });
};
