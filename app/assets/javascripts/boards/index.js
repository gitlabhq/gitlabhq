import PortalVue from 'portal-vue';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import toggleEpicsSwimlanes from 'ee_else_ce/boards/toggle_epics_swimlanes';
import toggleLabels from 'ee_else_ce/boards/toggle_labels';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import BoardApp from '~/boards/components/board_app.vue';
import '~/boards/filters/due_date_filters';
import { issuableTypes } from '~/boards/constants';
import eventHub from '~/boards/eventhub';
import FilteredSearchBoards from '~/boards/filtered_search_boards';
import initBoardsFilteredSearch from '~/boards/mount_filtered_search_issue_boards';
import store from '~/boards/stores';
import toggleFocusMode from '~/boards/toggle_focus';
import { NavigationType, isLoggedIn, parseBoolean } from '~/lib/utils/common_utils';
import { fullBoardId } from './boards_util';
import boardConfigToggle from './config_toggle';
import initNewBoard from './new_board';
import { gqlClient } from './graphql';
import mountMultipleBoardsSwitcher from './mount_multiple_boards_switcher';

Vue.use(VueApollo);
Vue.use(PortalVue);

const apolloProvider = new VueApollo({
  defaultClient: gqlClient,
});

function mountBoardApp(el) {
  const { boardId, groupId, fullPath, rootPath } = el.dataset;

  store.dispatch('setInitialBoardData', {
    boardId,
    fullBoardId: fullBoardId(boardId),
    fullPath,
    boardType: el.dataset.parent,
    disabled: parseBoolean(el.dataset.disabled) || true,
    issuableType: issuableTypes.issue,
    boardConfig: {
      milestoneId: parseInt(el.dataset.boardMilestoneId, 10),
      milestoneTitle: el.dataset.boardMilestoneTitle || '',
      iterationId: parseInt(el.dataset.boardIterationId, 10),
      iterationTitle: el.dataset.boardIterationTitle || '',
      assigneeId: el.dataset.boardAssigneeId,
      assigneeUsername: el.dataset.boardAssigneeUsername,
      labels: el.dataset.labels ? JSON.parse(el.dataset.labels) : [],
      labelIds: el.dataset.labelIds ? JSON.parse(el.dataset.labelIds) : [],
      weight: el.dataset.boardWeight ? parseInt(el.dataset.boardWeight, 10) : null,
    },
  });

  if (!gon?.features?.issueBoardsFilteredSearch) {
    // Warning: FilteredSearchBoards has an implicit dependency on the Vuex state 'boardConfig'
    // Improve this situation in the future.
    const filterManager = new FilteredSearchBoards({ path: '' }, true, []);
    filterManager.setup();

    eventHub.$on('updateTokens', () => {
      filterManager.updateTokens();
    });
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'BoardAppRoot',
    store,
    apolloProvider,
    provide: {
      disabled: parseBoolean(el.dataset.disabled),
      boardId,
      groupId: Number(groupId),
      rootPath,
      currentUserId: gon.current_user_id || null,
      canUpdate: parseBoolean(el.dataset.canUpdate),
      canAdminList: parseBoolean(el.dataset.canAdminList),
      labelsManagePath: el.dataset.labelsManagePath,
      labelsFilterBasePath: el.dataset.labelsFilterBasePath,
      timeTrackingLimitToHours: parseBoolean(el.dataset.timeTrackingLimitToHours),
      multipleAssigneesFeatureAvailable: parseBoolean(el.dataset.multipleAssigneesFeatureAvailable),
      epicFeatureAvailable: parseBoolean(el.dataset.epicFeatureAvailable),
      iterationFeatureAvailable: parseBoolean(el.dataset.iterationFeatureAvailable),
      weightFeatureAvailable: parseBoolean(el.dataset.weightFeatureAvailable),
      boardWeight: el.dataset.boardWeight ? parseInt(el.dataset.boardWeight, 10) : null,
      scopedLabelsAvailable: parseBoolean(el.dataset.scopedLabels),
      milestoneListsAvailable: parseBoolean(el.dataset.milestoneListsAvailable),
      assigneeListsAvailable: parseBoolean(el.dataset.assigneeListsAvailable),
      iterationListsAvailable: parseBoolean(el.dataset.iterationListsAvailable),
      issuableType: issuableTypes.issue,
      emailsDisabled: parseBoolean(el.dataset.emailsDisabled),
      allowLabelCreate: parseBoolean(el.dataset.canUpdate),
      allowLabelEdit: parseBoolean(el.dataset.canUpdate),
      allowScopedLabels: parseBoolean(el.dataset.scopedLabels),
    },
    render: (createComponent) => createComponent(BoardApp),
  });
}

export default () => {
  const $boardApp = document.getElementById('js-issuable-board-app');

  // check for browser back and trigger a hard reload to circumvent browser caching.
  window.addEventListener('pageshow', (event) => {
    const isNavTypeBackForward =
      window.performance && window.performance.navigation.type === NavigationType.TYPE_BACK_FORWARD;

    if (event.persisted || isNavTypeBackForward) {
      window.location.reload();
    }
  });

  if (gon?.features?.issueBoardsFilteredSearch) {
    const { releasesFetchPath } = $boardApp.dataset;
    initBoardsFilteredSearch(apolloProvider, isLoggedIn(), releasesFetchPath);
  }

  mountBoardApp($boardApp);

  const createColumnTriggerEl = document.querySelector('.js-create-column-trigger');
  if (createColumnTriggerEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: createColumnTriggerEl,
      name: 'BoardAddNewColumnTriggerRoot',
      components: {
        BoardAddNewColumnTrigger,
      },
      store,
      render(createElement) {
        return createElement('board-add-new-column-trigger');
      },
    });
  }

  boardConfigToggle();
  initNewBoard();

  toggleFocusMode();
  toggleLabels();

  if (gon.licensed_features?.swimlanes) {
    toggleEpicsSwimlanes();
  }

  mountMultipleBoardsSwitcher({
    fullPath: $boardApp.dataset.fullPath,
    rootPath: $boardApp.dataset.boardsEndpoint,
    allowScopedLabels: $boardApp.dataset.scopedLabels,
    labelsManagePath: $boardApp.dataset.labelsManagePath,
  });
};
