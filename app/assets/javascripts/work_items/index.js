import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { DESIGN_MARK_APP_START, DESIGN_MEASURE_BEFORE_APP } from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { WORKSPACE_GROUP } from '~/issues/constants';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { parseBoolean } from '~/lib/utils/common_utils';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import App from './components/app.vue';
import WorkItemBreadcrumb from './components/work_item_breadcrumb.vue';
import activeDiscussionQuery from './components/design_management/graphql/client/active_design_discussion.query.graphql';
import { WORK_ITEM_TYPE_NAME_EPIC } from './constants';
import { createRouter } from './router';

Vue.use(VueApollo);

export const initWorkItemsRoot = ({ workItemType, workspaceType, withTabs } = {}) => {
  const el = document.querySelector('#js-work-items');

  if (!el) {
    return undefined;
  }

  addShortcutsExtension(ShortcutsNavigation);

  const {
    canBulkUpdate,
    fullPath,
    groupPath,
    groupId,
    hasIssueWeightsFeature,
    issuesListPath,
    epicsListPath,
    labelsManagePath,
    registerPath,
    signInPath,
    hasBlockedIssuesFeature,
    hasGroupBulkEditFeature,
    hasIterationsFeature,
    hasOkrsFeature,
    hasSubepicsFeature,
    hasIssuableHealthStatusFeature,
    hasCustomFieldsFeature,
    newTrialPath,
    reportAbusePath,
    defaultBranch,
    initialSort,
    isSignedIn,
    hasEpicsFeature,
    showNewWorkItem,
    autocompleteAwardEmojisPath,
    hasScopedLabelsFeature,
    hasQualityManagementFeature,
    canBulkEditEpics,
    groupIssuesPath,
    labelsFetchPath,
    hasLinkedItemsEpicsFeature,
    duoRemoteFlowsAvailability,
    canCreateProjects,
    newProjectPath,
    projectNamespaceFullPath,
    hasIssueDateFilterFeature,
    timeTrackingLimitToHours,
    hasStatusFeature,
    workItemPlanningViewEnabled,
    canReadCrmOrganization,
    canReadCrmContact,
    releasesPath,
    projectImportJiraPath,
    rssPath,
    calendarPath,
    maxAttachmentSize,
    canImportWorkItems,
    isGroupIssuesList,
    canEdit,
    exportCsvPath,
    isIssueRepositioningDisabled,
    hasProjects,
    newIssuePath,
  } = el.dataset;

  const isGroup = workspaceType === WORKSPACE_GROUP;
  const router = createRouter({ fullPath, workspaceType, defaultBranch });
  let listPath = issuesListPath;

  const breadcrumbParams = { workItemType, isGroup };

  if (workItemType === WORK_ITEM_TYPE_NAME_EPIC) {
    listPath = epicsListPath;
    breadcrumbParams.listPath = epicsListPath;
  } else {
    breadcrumbParams.listPath = issuesListPath;
  }

  injectVueAppBreadcrumbs(router, WorkItemBreadcrumb, apolloProvider, breadcrumbParams);

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: activeDiscussionQuery,
    data: {
      activeDesignDiscussion: {
        __typename: 'ActiveDesignDiscussion',
        id: null,
        source: null,
      },
    },
  });

  return new Vue({
    el,
    name: 'WorkItemsRoot',
    router,
    apolloProvider,
    provide: {
      canBulkUpdate: parseBoolean(canBulkUpdate),
      duoRemoteFlowsAvailability: parseBoolean(duoRemoteFlowsAvailability),
      fullPath,
      isGroup,
      isProject: !isGroup,
      isGroupIssuesList: parseBoolean(isGroupIssuesList),
      hasBlockedIssuesFeature: parseBoolean(hasBlockedIssuesFeature),
      hasGroupBulkEditFeature: parseBoolean(hasGroupBulkEditFeature),
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasOkrsFeature: parseBoolean(hasOkrsFeature),
      hasSubepicsFeature: parseBoolean(hasSubepicsFeature),
      hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
      issuesListPath: listPath,
      labelsManagePath,
      registerPath,
      signInPath,
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      hasCustomFieldsFeature: parseBoolean(hasCustomFieldsFeature),
      newTrialPath,
      reportAbusePath,
      groupPath,
      groupId,
      initialSort,
      isSignedIn: parseBoolean(isSignedIn),
      workItemType,
      hasEpicsFeature: parseBoolean(hasEpicsFeature),
      showNewWorkItem: parseBoolean(showNewWorkItem),
      autocompleteAwardEmojisPath,
      hasQualityManagementFeature: parseBoolean(hasQualityManagementFeature),
      canBulkEditEpics: parseBoolean(canBulkEditEpics),
      groupIssuesPath,
      labelsFetchPath,
      hasLinkedItemsEpicsFeature: parseBoolean(hasLinkedItemsEpicsFeature),
      canCreateProjects: parseBoolean(canCreateProjects),
      newIssuePath,
      newProjectPath,
      projectNamespaceFullPath,
      hasIssueDateFilterFeature: parseBoolean(hasIssueDateFilterFeature),
      timeTrackingLimitToHours: parseBoolean(timeTrackingLimitToHours),
      hasStatusFeature: parseBoolean(hasStatusFeature),
      workItemPlanningViewEnabled: parseBoolean(workItemPlanningViewEnabled),
      canReadCrmOrganization: parseBoolean(canReadCrmOrganization),
      canReadCrmContact: parseBoolean(canReadCrmContact),
      releasesPath,
      projectImportJiraPath,
      rssPath,
      calendarPath,
      maxAttachmentSize,
      canImportWorkItems: parseBoolean(canImportWorkItems),
      showImportButton: parseBoolean(canImportWorkItems),
      canEdit: parseBoolean(canEdit),
      exportCsvPath,
      showNewIssueLink: parseBoolean(showNewWorkItem),
      isIssueRepositioningDisabled: parseBoolean(isIssueRepositioningDisabled),
      hasProjects: parseBoolean(hasProjects),
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
          rootPageFullPath: fullPath,
          withTabs,
        },
      });
    },
  });
};
