import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import { gqlClient } from './graphql';
import ServiceDeskListApp from './components/service_desk_list_app.vue';

export async function mountServiceDeskListApp() {
  const el = document.querySelector('.js-service-desk-list');

  if (!el) {
    return null;
  }

  const {
    projectDataReleasesPath,
    projectDataAutocompleteAwardEmojisPath,
    projectDataHasIterationsFeature,
    projectDataHasIssueWeightsFeature,
    projectDataHasIssuableHealthStatusFeature,
    projectDataGroupPath,
    projectDataEmptyStateSvgPath,
    projectDataFullPath,
    projectDataIsProject,
    projectDataIsSignedIn,
    projectDataHasAnyIssues,
    serviceDeskEmailAddress,
    canAdminIssues,
    canEditProjectSettings,
    serviceDeskCalloutSvgPath,
    serviceDeskSettingsPath,
    serviceDeskHelpPath,
    isServiceDeskSupported,
    isServiceDeskEnabled,
  } = el.dataset;

  Vue.use(VueApollo);

  return new Vue({
    el,
    name: 'ServiceDeskListRoot',
    apolloProvider: new VueApollo({
      defaultClient: await gqlClient(),
    }),
    provide: {
      releasesPath: projectDataReleasesPath,
      autocompleteAwardEmojisPath: projectDataAutocompleteAwardEmojisPath,
      hasIterationsFeature: parseBoolean(projectDataHasIterationsFeature),
      hasIssueWeightsFeature: parseBoolean(projectDataHasIssueWeightsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(projectDataHasIssuableHealthStatusFeature),
      groupPath: projectDataGroupPath,
      emptyStateSvgPath: projectDataEmptyStateSvgPath,
      fullPath: projectDataFullPath,
      isProject: parseBoolean(projectDataIsProject),
      isSignedIn: parseBoolean(projectDataIsSignedIn),
      serviceDeskEmailAddress,
      canAdminIssues: parseBoolean(canAdminIssues),
      canEditProjectSettings: parseBoolean(canEditProjectSettings),
      serviceDeskCalloutSvgPath,
      serviceDeskSettingsPath,
      serviceDeskHelpPath,
      isServiceDeskSupported: parseBoolean(isServiceDeskSupported),
      isServiceDeskEnabled: parseBoolean(isServiceDeskEnabled),
      hasAnyIssues: parseBoolean(projectDataHasAnyIssues),
    },
    render: (createComponent) => createComponent(ServiceDeskListApp),
  });
}
