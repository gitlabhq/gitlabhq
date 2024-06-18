import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

export const initOrganizationsGroupsNew = () => {
  const el = document.getElementById('js-organizations-groups-new');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const {
    basePath,
    groupsAndProjectsOrganizationPath,
    groupsOrganizationPath,
    availableVisibilityLevels,
    restrictedVisibilityLevels,
    defaultVisibilityLevel,
    pathMaxlength,
    pathPattern,
  } = convertObjectPropsToCamelCase(JSON.parse(appData));

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'OrganizationGroupsNewRoot',
    apolloProvider,
    provide: {
      basePath,
      groupsAndProjectsOrganizationPath,
      groupsOrganizationPath,
      availableVisibilityLevels,
      restrictedVisibilityLevels,
      defaultVisibilityLevel,
      pathMaxlength,
      pathPattern,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
