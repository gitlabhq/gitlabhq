import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { DESIGN_MARK_APP_START, DESIGN_MEASURE_BEFORE_APP } from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { WORKSPACE_GROUP } from '~/issues/constants';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsWorkItems from '~/behaviors/shortcuts/shortcuts_work_items';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { parseBoolean } from '~/lib/utils/common_utils';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import App from './components/app.vue';
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
  } = el.dataset;

  const isGroup = workspaceType === WORKSPACE_GROUP;

  return new Vue({
    el,
    name: 'WorkItemsRoot',
    router: createRouter({ fullPath, workItemType, workspaceType, defaultBranch }),
    apolloProvider,
    provide: {
      canAdminLabel,
      fullPath,
      isGroup,
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasOkrsFeature: parseBoolean(hasOkrsFeature),
      hasSubepicsFeature: parseBoolean(hasSubepicsFeature),
      issuesListPath,
      labelsManagePath,
      registerPath,
      signInPath,
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      newCommentTemplatePaths: JSON.parse(newCommentTemplatePaths),
      reportAbusePath,
      groupPath,
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
