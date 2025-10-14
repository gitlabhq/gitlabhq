import Vue from 'vue';
import VueApollo from 'vue-apollo';
import IssuesDashboardApp from 'ee_else_ce/issues/dashboard/components/issues_dashboard_app.vue';
import { gqlClient } from '~/issues/list/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';

export async function mountIssuesDashboardApp() {
  const el = document.querySelector('.js-issues-dashboard');

  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  const {
    autocompleteAwardEmojisPath,
    autocompleteUsersPath,
    calendarPath,
    dashboardLabelsPath,
    dashboardMilestonesPath,
    emptyStateWithFilterSvgPath,
    emptyStateWithoutFilterSvgPath,
    hasBlockedIssuesFeature,
    hasIssuableHealthStatusFeature,
    hasIterationsFeature,
    hasIssueDateFilterFeature,
    hasIssueWeightsFeature,
    hasOkrsFeature,
    hasQualityManagementFeature,
    hasScopedLabelsFeature,
    hasStatusFeature,
    initialSort,
    isPublicVisibilityRestricted,
    isSignedIn,
    rssPath,
  } = el.dataset;

  return new Vue({
    el,
    name: 'IssuesDashboardRoot',
    apolloProvider: new VueApollo({
      defaultClient: await gqlClient(),
    }),
    provide: {
      autocompleteAwardEmojisPath,
      autocompleteUsersPath,
      calendarPath,
      dashboardLabelsPath,
      dashboardMilestonesPath,
      emptyStateWithFilterSvgPath,
      emptyStateWithoutFilterSvgPath,
      hasBlockedIssuesFeature: parseBoolean(hasBlockedIssuesFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasIssueDateFilterFeature: parseBoolean(hasIssueDateFilterFeature),
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasOkrsFeature: parseBoolean(hasOkrsFeature),
      hasQualityManagementFeature: parseBoolean(hasQualityManagementFeature),
      hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
      hasStatusFeature: parseBoolean(hasStatusFeature),
      initialSort,
      isPublicVisibilityRestricted: parseBoolean(isPublicVisibilityRestricted),
      isSignedIn: parseBoolean(isSignedIn),
      rssPath,
    },
    render: (createComponent) => createComponent(IssuesDashboardApp),
  });
}
