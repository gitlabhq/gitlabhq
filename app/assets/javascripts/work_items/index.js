import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { DESIGN_MARK_APP_START, DESIGN_MEASURE_BEFORE_APP } from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { WORKSPACE_GROUP } from '~/issues/constants';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsWorkItems from '~/behaviors/shortcuts/shortcuts_work_items';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { parseBoolean } from '~/lib/utils/common_utils';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import App from './components/app.vue';
import WorkItemBreadcrumb from './components/work_item_breadcrumb.vue';
import { createRouter } from './router';

Vue.use(VueApollo);

export const initWorkItemsRoot = ({ workItemType, workspaceType } = {}) => {
  const el = document.querySelector('#js-work-items');

  if (!el) {
    return undefined;
  }

  addShortcutsExtension(ShortcutsNavigation);
  addShortcutsExtension(ShortcutsWorkItems);

  const {
    canAdminLabel,
    fullPath,
    groupPath,
    hasIssueWeightsFeature,
    iid,
    issuesListPath,
    labelsManagePath,
    registerPath,
    signInPath,
    hasIterationsFeature,
    hasOkrsFeature,
    hasSubepicsFeature,
    hasIssuableHealthStatusFeature,
    newCommentTemplatePaths,
    reportAbusePath,
    defaultBranch,
    initialSort,
    isSignedIn,
    workItemType: listWorkItemType,
    hasEpicsFeature,
    showNewIssueLink,
    canCreateEpic,
    autocompleteAwardEmojisPath,
    hasScopedLabelsFeature,
    hasQualityManagementFeature,
    canBulkEditEpics,
    groupIssuesPath,
    labelsFetchPath,
  } = el.dataset;

  const isGroup = workspaceType === WORKSPACE_GROUP;
  const router = createRouter({ fullPath, workItemType, workspaceType, defaultBranch, isGroup });

  if (isGroup)
    injectVueAppBreadcrumbs(router, WorkItemBreadcrumb, apolloProvider, {
      workItemType: listWorkItemType,
    });

  return new Vue({
    el,
    name: 'WorkItemsRoot',
    router,
    apolloProvider,
    provide: {
      canAdminLabel,
      fullPath,
      isGroup,
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasOkrsFeature: parseBoolean(hasOkrsFeature),
      hasSubepicsFeature: parseBoolean(hasSubepicsFeature),
      hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
      issuesListPath,
      labelsManagePath,
      registerPath,
      signInPath,
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      newCommentTemplatePaths: JSON.parse(newCommentTemplatePaths),
      reportAbusePath,
      groupPath,
      initialSort,
      isSignedIn: parseBoolean(isSignedIn),
      workItemType: listWorkItemType,
      hasEpicsFeature: parseBoolean(hasEpicsFeature),
      showNewIssueLink: parseBoolean(showNewIssueLink),
      canCreateEpic: parseBoolean(canCreateEpic),
      autocompleteAwardEmojisPath,
      hasQualityManagementFeature: parseBoolean(hasQualityManagementFeature),
      canBulkEditEpics: parseBoolean(canBulkEditEpics),
      groupIssuesPath,
      labelsFetchPath,
    },
    mounted() {
      performanceMarkAndMeasure({
        mark: DESIGN_MARK_APP_START,
        measures: [
          {
            name: DESIGN_MEASURE_BEFORE_APP,
          },
        ],
      });
    },
    render(createElement) {
      return createElement(App, {
        props: {
          iid: isGroup ? iid : undefined,
        },
      });
    },
  });
};
