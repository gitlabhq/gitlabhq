import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { DESIGN_MARK_APP_START, DESIGN_MEASURE_BEFORE_APP } from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { NAMESPACE_GROUP } from '~/issues/constants';
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
    issuesListPath,
    epicsListPath,
    defaultBranch,
    isGroupIssuesList,
    workItemPlanningViewEnabled,
    workItemsSavedViewsEnabled,
    // service desk list
    isServiceDeskEnabled,
    isServiceDeskSupported,
    serviceDeskCalloutSvgPath,
    serviceDeskEmailAddress,
    serviceDeskHelpPath,
    serviceDeskSettingsPath,
  } = el.dataset;

  const isGroup = workspaceType === NAMESPACE_GROUP;
  const router = createRouter({ fullPath, workspaceType, defaultBranch, workItemType });

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
      fullPath,
      isGroup,
      isProject: !isGroup,
      isGroupIssuesList: parseBoolean(isGroupIssuesList),
      workItemType,
      workItemPlanningViewEnabled: parseBoolean(workItemPlanningViewEnabled),
      workItemsSavedViewsEnabled: parseBoolean(workItemsSavedViewsEnabled),
      // service desk list
      isServiceDeskEnabled: parseBoolean(isServiceDeskEnabled),
      isServiceDeskSupported: parseBoolean(isServiceDeskSupported),
      serviceDeskCalloutSvgPath,
      serviceDeskEmailAddress,
      serviceDeskHelpPath,
      serviceDeskSettingsPath,
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
