import PortalVue from 'portal-vue';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import BoardApp from '~/boards/components/board_app.vue';
import { TYPE_ISSUE, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import {
  navigationType,
  isLoggedIn,
  parseBoolean,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { defaultClient } from '~/graphql_shared/issuable_client';
import { fullBoardId } from './boards_util';

Vue.use(VueApollo);
Vue.use(PortalVue);

defaultClient.cache.policies.addTypePolicies({
  BoardList: {
    fields: {
      issues: {
        keyArgs: ['filters'],
      },
    },
  },
  IssueConnection: {
    merge(existing = { nodes: [] }, incoming, { args }) {
      if (!args?.after) {
        return incoming;
      }
      return {
        ...incoming,
        nodes: [...existing.nodes, ...incoming.nodes],
      };
    },
  },
  BoardEpicConnection: {
    merge(existing = { nodes: [] }, incoming, { args }) {
      if (!args.after) {
        return incoming;
      }
      return {
        ...incoming,
        nodes: [...existing.nodes, ...incoming.nodes],
      };
    },
  },
  Board: {
    fields: {
      epics: {
        keyArgs: ['boardId', 'issueFilters'],
      },
    },
  },
});

const apolloProvider = new VueApollo({
  defaultClient,
});

function mountBoardApp(el) {
  const {
    boardId,
    groupId,
    fullPath,
    rootPath,
    wiHasScopedLabelsFeature,
    wiGroupPath,
    wiCanAdminLabel,
    wiNewCommentTemplatePaths,
  } = el.dataset;

  const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });

  const initialFilterParams = {
    ...convertObjectPropsToCamelCase(rawFilterParams, {}),
  };

  const boardType = el.dataset.parent;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'BoardAppRoot',
    apolloProvider,
    provide: {
      initialBoardId: fullBoardId(boardId),
      disabled: parseBoolean(el.dataset.disabled),
      groupId: Number(groupId),
      rootPath,
      fullPath,
      groupPath: wiGroupPath,
      initialFilterParams,
      boardBaseUrl: el.dataset.boardBaseUrl,
      boardType,
      isGroup: boardType === WORKSPACE_GROUP,
      isGroupBoard: boardType === WORKSPACE_GROUP,
      isProjectBoard: boardType === WORKSPACE_PROJECT,
      currentUserId: gon.current_user_id || null,
      boardWeight: el.dataset.boardWeight ? parseInt(el.dataset.boardWeight, 10) : null,
      labelsManagePath: el.dataset.labelsManagePath,
      labelsFilterBasePath: el.dataset.labelsFilterBasePath,
      releasesFetchPath: el.dataset.releasesFetchPath,
      timeTrackingLimitToHours: parseBoolean(el.dataset.timeTrackingLimitToHours),
      issuableType: TYPE_ISSUE,
      emailsEnabled: parseBoolean(el.dataset.emailsEnabled),
      hasMissingBoards: parseBoolean(el.dataset.hasMissingBoards),
      weights: el.dataset.weights ? JSON.parse(el.dataset.weights) : [],
      isIssueBoard: true,
      isEpicBoard: false,
      reportAbusePath: el.dataset.wiReportAbusePath,
      issuesListPath: el.dataset.wiIssuesListPath,
      // Permissions
      canUpdate: parseBoolean(el.dataset.canUpdate),
      canAdminList: parseBoolean(el.dataset.canAdminList),
      canAdminBoard: parseBoolean(el.dataset.canAdminBoard),
      allowLabelCreate: parseBoolean(el.dataset.canUpdate),
      allowLabelEdit: parseBoolean(el.dataset.canUpdate),
      isSignedIn: isLoggedIn(),
      canAdminLabel: parseBoolean(wiCanAdminLabel),
      // Features
      multipleAssigneesFeatureAvailable: parseBoolean(el.dataset.multipleAssigneesFeatureAvailable),
      epicFeatureAvailable: parseBoolean(el.dataset.epicFeatureAvailable),
      iterationFeatureAvailable: parseBoolean(el.dataset.iterationFeatureAvailable),
      weightFeatureAvailable: parseBoolean(el.dataset.weightFeatureAvailable),
      scopedLabelsAvailable: parseBoolean(el.dataset.scopedLabels),
      milestoneListsAvailable: parseBoolean(el.dataset.milestoneListsAvailable),
      assigneeListsAvailable: parseBoolean(el.dataset.assigneeListsAvailable),
      iterationListsAvailable: parseBoolean(el.dataset.iterationListsAvailable),
      healthStatusFeatureAvailable: parseBoolean(el.dataset.healthStatusFeatureAvailable),
      allowScopedLabels: parseBoolean(el.dataset.scopedLabels),
      swimlanesFeatureAvailable: gon.licensed_features?.swimlanes,
      multipleIssueBoardsAvailable: parseBoolean(el.dataset.multipleBoardsAvailable),
      scopedIssueBoardFeatureEnabled: parseBoolean(el.dataset.scopedIssueBoardFeatureEnabled),
      allowSubEpics: false,
      hasScopedLabelsFeature: parseBoolean(wiHasScopedLabelsFeature),
      hasIterationsFeature: parseBoolean(el.dataset.iterationFeatureAvailable),
      hasIssueWeightsFeature: parseBoolean(el.dataset.weightFeatureAvailable),
      hasIssuableHealthStatusFeature: parseBoolean(el.dataset.healthStatusFeatureAvailable),
      hasSubepicsFeature: parseBoolean(el.dataset.subEpicsFeatureAvailable),
      hasLinkedItemsEpicsFeature: parseBoolean(el.dataset.hasLinkedItemsEpicsFeature),
      hasOkrsFeature: parseBoolean(el.dataset.hasOkrsFeature),
      commentTemplatePaths: JSON.parse(wiNewCommentTemplatePaths),
    },
    render: (createComponent) => createComponent(BoardApp),
  });
}

export default () => {
  const $boardApp = document.getElementById('js-issuable-board-app');

  // check for browser back and trigger a hard reload to circumvent browser caching.
  window.addEventListener('pageshow', (event) => {
    const isNavTypeBackForward =
      window.performance && window.performance.navigation.type === navigationType.TYPE_BACK_FORWARD;

    if (event.persisted || isNavTypeBackForward) {
      window.location.reload();
    }
  });

  mountBoardApp($boardApp);
};
