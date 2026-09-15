import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

export const initOrganizationsGroupsEdit = () => {
  const el = document.getElementById('js-organizations-groups-edit');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const {
    group,
    basePath,
    groupsAndProjectsOrganizationPath,
    availableVisibilityLevels,
    restrictedVisibilityLevels,
    pathMaxlength,
    pathPattern,
  } = convertObjectPropsToCamelCase(JSON.parse(appData), { deep: true });

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'OrganizationGroupsEditRoot',
    apolloProvider,
    provide: {
      group,
      basePath,
      groupsAndProjectsOrganizationPath,
      availableVisibilityLevels,
      restrictedVisibilityLevels,
      pathMaxlength,
      pathPattern,
    },
    component: App,
  });
};
