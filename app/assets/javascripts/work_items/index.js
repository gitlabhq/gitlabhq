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
    fullPath,
    groupId,
    issuesListPath,
    epicsListPath,
    defaultBranch,
    initialSort,
    isSignedIn,
    showNewWorkItem,
    duoRemoteFlowsAvailability,
    projectNamespaceFullPath,
    timeTrackingLimitToHours,
    workItemPlanningViewEnabled,
    canReadCrmOrganization,
    canReadCrmContact,
    maxAttachmentSize,
    isGroupIssuesList,
    isIssueRepositioningDisabled,
    hasProjects,
    workItemsSavedViewsEnabled,
  } = el.dataset;

  const isGroup = workspaceType === WORKSPACE_GROUP;
  const router = createRouter({ fullPath, workspaceType, defaultBranch });

  const breadcrumbParams = { workItemType };

  if (workItemType === WORK_ITEM_TYPE_NAME_EPIC) {
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
      duoRemoteFlowsAvailability: parseBoolean(duoRemoteFlowsAvailability),
      fullPath,
      isGroup,
      isProject: !isGroup,
      isGroupIssuesList: parseBoolean(isGroupIssuesList),
      groupId,
      initialSort,
      isSignedIn: parseBoolean(isSignedIn),
      workItemType,
      showNewWorkItem: parseBoolean(showNewWorkItem),
      projectNamespaceFullPath,
      timeTrackingLimitToHours: parseBoolean(timeTrackingLimitToHours),
      workItemPlanningViewEnabled: parseBoolean(workItemPlanningViewEnabled),
      canReadCrmOrganization: parseBoolean(canReadCrmOrganization),
      canReadCrmContact: parseBoolean(canReadCrmContact),
      maxAttachmentSize,
      showNewIssueLink: parseBoolean(showNewWorkItem),
      isIssueRepositioningDisabled: parseBoolean(isIssueRepositioningDisabled),
      hasProjects: parseBoolean(hasProjects),
      workItemsSavedViewsEnabled: parseBoolean(workItemsSavedViewsEnabled),
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
