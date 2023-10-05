import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { parseBoolean } from '~/lib/utils/common_utils';
import ServiceDeskListApp from 'ee_else_ce/issues/service_desk/components/service_desk_list_app.vue';
import FilteredSearchServiceDesk from './filtered_search_service_desk';
import { gqlClient } from './graphql';

export function initFilteredSearchServiceDesk() {
  if (document.querySelector('.filtered-search')) {
    const supportBotData = JSON.parse(
      document.querySelector('.js-service-desk-issues').dataset.supportBot,
    );
    const filteredSearchManager = new FilteredSearchServiceDesk(supportBotData);
    filteredSearchManager.setup();
  }
}

export async function mountServiceDeskListApp() {
  const el = document.querySelector('.js-service-desk-list');

  if (!el) {
    return null;
  }

  const {
    projectDataReleasesPath,
    projectDataAutocompleteAwardEmojisPath,
    projectDataHasBlockedIssuesFeature,
    projectDataHasIterationsFeature,
    projectDataHasIssueWeightsFeature,
    projectDataHasIssuableHealthStatusFeature,
    projectDataGroupPath,
    projectDataEmptyStateSvgPath,
    projectDataFullPath,
    projectDataIsProject,
    projectDataIsSignedIn,
    projectDataSignInPath,
    projectDataHasAnyIssues,
    projectDataInitialSort,
    projectDataIsIssueRepositioningDisabled,
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
  Vue.use(VueRouter);

  return new Vue({
    el,
    name: 'ServiceDeskListRoot',
    apolloProvider: new VueApollo({
      defaultClient: await gqlClient(),
    }),
    router: new VueRouter({
      base: window.location.pathname,
      mode: 'history',
      routes: [{ path: '/' }],
    }),
    provide: {
      releasesPath: projectDataReleasesPath,
      autocompleteAwardEmojisPath: projectDataAutocompleteAwardEmojisPath,
      hasBlockedIssuesFeature: parseBoolean(projectDataHasBlockedIssuesFeature),
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
      signInPath: projectDataSignInPath,
      hasAnyIssues: parseBoolean(projectDataHasAnyIssues),
      initialSort: projectDataInitialSort,
      isIssueRepositioningDisabled: parseBoolean(projectDataIsIssueRepositioningDisabled),
    },
    render: (createComponent) => createComponent(ServiceDeskListApp),
  });
}
