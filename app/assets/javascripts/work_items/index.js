import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { DESIGN_MARK_APP_START, DESIGN_MEASURE_BEFORE_APP } from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { parseBoolean } from '~/lib/utils/common_utils';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import App from './components/app.vue';
import WorkItemBreadcrumb from './components/work_item_breadcrumb.vue';
import activeDiscussionQuery from './components/design_management/graphql/client/active_design_discussion.query.graphql';
import { createRouter } from './router';

Vue.use(VueApollo);

export const initWorkItemsRoot = ({ workItemType, withTabs } = {}) => {
  const el = document.querySelector('#js-work-items');

  if (!el) {
    return undefined;
  }

  addShortcutsExtension(ShortcutsNavigation);

  const {
    fullPath,
    defaultBranch,
    routerPath,
    // group work items list
    isGroupIssuesList,
    // service desk list
    isServiceDeskEnabled,
    isServiceDeskSupported,
    serviceDeskCalloutSvgPath,
    serviceDeskEmailAddress,
    serviceDeskHelpPath,
    serviceDeskSettingsPath,
  } = el.dataset;

  const router = createRouter({ fullPath, defaultBranch, routerPath });

  injectVueAppBreadcrumbs(router, WorkItemBreadcrumb, apolloProvider, { workItemType });

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
      workItemType,
      // group work items list
      isGroupIssuesList: parseBoolean(isGroupIssuesList),
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
