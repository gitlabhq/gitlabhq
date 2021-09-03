import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import PortalVue from 'portal-vue';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mapActions } from 'vuex';

import toggleEpicsSwimlanes from 'ee_else_ce/boards/toggle_epics_swimlanes';
import toggleLabels from 'ee_else_ce/boards/toggle_labels';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import BoardContent from '~/boards/components/board_content.vue';
import '~/boards/filters/due_date_filters';
import { issuableTypes } from '~/boards/constants';
import eventHub from '~/boards/eventhub';
import FilteredSearchBoards from '~/boards/filtered_search_boards';
import initBoardsFilteredSearch from '~/boards/mount_filtered_search_issue_boards';
import store from '~/boards/stores';
import toggleFocusMode from '~/boards/toggle_focus';
import createDefaultClient from '~/lib/graphql';
import { NavigationType, parseBoolean } from '~/lib/utils/common_utils';
import introspectionQueryResultData from '~/sidebar/fragmentTypes.json';
import { fullBoardId } from './boards_util';
import boardConfigToggle from './config_toggle';
import mountMultipleBoardsSwitcher from './mount_multiple_boards_switcher';

Vue.use(VueApollo);
Vue.use(PortalVue);

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      cacheConfig: {
        fragmentMatcher,
      },
      assumeImmutableResults: true,
    },
  ),
});

let issueBoardsApp;

export default () => {
  const $boardApp = document.getElementById('board-app');
  // check for browser back and trigger a hard reload to circumvent browser caching.
  window.addEventListener('pageshow', (event) => {
    const isNavTypeBackForward =
      window.performance && window.performance.navigation.type === NavigationType.TYPE_BACK_FORWARD;

    if (event.persisted || isNavTypeBackForward) {
      window.location.reload();
    }
  });

  if (issueBoardsApp) {
    issueBoardsApp.$destroy(true);
  }

  if (gon?.features?.issueBoardsFilteredSearch) {
    initBoardsFilteredSearch(apolloProvider);
  }

  // eslint-disable-next-line @gitlab/no-runtime-template-compiler
  issueBoardsApp = new Vue({
    el: $boardApp,
    components: {
      BoardContent,
      BoardSettingsSidebar: () => import('~/boards/components/board_settings_sidebar.vue'),
    },
    provide: {
      boardId: $boardApp.dataset.boardId,
      groupId: Number($boardApp.dataset.groupId),
      rootPath: $boardApp.dataset.rootPath,
      currentUserId: gon.current_user_id || null,
      canUpdate: parseBoolean($boardApp.dataset.canUpdate),
      canAdminList: parseBoolean($boardApp.dataset.canAdminList),
      labelsManagePath: $boardApp.dataset.labelsManagePath,
      labelsFilterBasePath: $boardApp.dataset.labelsFilterBasePath,
      timeTrackingLimitToHours: parseBoolean($boardApp.dataset.timeTrackingLimitToHours),
      multipleAssigneesFeatureAvailable: parseBoolean(
        $boardApp.dataset.multipleAssigneesFeatureAvailable,
      ),
      epicFeatureAvailable: parseBoolean($boardApp.dataset.epicFeatureAvailable),
      iterationFeatureAvailable: parseBoolean($boardApp.dataset.iterationFeatureAvailable),
      weightFeatureAvailable: parseBoolean($boardApp.dataset.weightFeatureAvailable),
      boardWeight: $boardApp.dataset.boardWeight
        ? parseInt($boardApp.dataset.boardWeight, 10)
        : null,
      scopedLabelsAvailable: parseBoolean($boardApp.dataset.scopedLabels),
      milestoneListsAvailable: parseBoolean($boardApp.dataset.milestoneListsAvailable),
      assigneeListsAvailable: parseBoolean($boardApp.dataset.assigneeListsAvailable),
      iterationListsAvailable: parseBoolean($boardApp.dataset.iterationListsAvailable),
      issuableType: issuableTypes.issue,
      emailsDisabled: parseBoolean($boardApp.dataset.emailsDisabled),
    },
    store,
    apolloProvider,
    data() {
      return {
        loading: 0,
        recentBoardsEndpoint: $boardApp.dataset.recentBoardsEndpoint,
        disabled: parseBoolean($boardApp.dataset.disabled),
        parent: $boardApp.dataset.parent,
        detailIssueVisible: false,
      };
    },
    created() {
      this.setInitialBoardData({
        boardId: $boardApp.dataset.boardId,
        fullBoardId: fullBoardId($boardApp.dataset.boardId),
        fullPath: $boardApp.dataset.fullPath,
        boardType: this.parent,
        disabled: this.disabled,
        issuableType: issuableTypes.issue,
        boardConfig: {
          milestoneId: parseInt($boardApp.dataset.boardMilestoneId, 10),
          milestoneTitle: $boardApp.dataset.boardMilestoneTitle || '',
          iterationId: parseInt($boardApp.dataset.boardIterationId, 10),
          iterationTitle: $boardApp.dataset.boardIterationTitle || '',
          assigneeId: $boardApp.dataset.boardAssigneeId,
          assigneeUsername: $boardApp.dataset.boardAssigneeUsername,
          labels: $boardApp.dataset.labels ? JSON.parse($boardApp.dataset.labels) : [],
          labelIds: $boardApp.dataset.labelIds ? JSON.parse($boardApp.dataset.labelIds) : [],
          weight: $boardApp.dataset.boardWeight
            ? parseInt($boardApp.dataset.boardWeight, 10)
            : null,
        },
      });

      eventHub.$on('updateTokens', this.updateTokens);
      eventHub.$on('toggleDetailIssue', this.toggleDetailIssue);
    },
    beforeDestroy() {
      eventHub.$off('updateTokens', this.updateTokens);
      eventHub.$off('toggleDetailIssue', this.toggleDetailIssue);
    },
    mounted() {
      if (!gon?.features?.issueBoardsFilteredSearch) {
        this.filterManager = new FilteredSearchBoards({ path: '' }, true, []);
        this.filterManager.setup();
      }

      this.performSearch();
    },
    methods: {
      ...mapActions(['setInitialBoardData', 'performSearch', 'setError']),
      updateTokens() {
        this.filterManager.updateTokens();
      },
      toggleDetailIssue(hasSidebar) {
        this.detailIssueVisible = hasSidebar;
      },
    },
  });

  const createColumnTriggerEl = document.querySelector('.js-create-column-trigger');
  if (createColumnTriggerEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: createColumnTriggerEl,
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

  toggleFocusMode();
  toggleLabels();

  if (gon.licensed_features?.swimlanes) {
    toggleEpicsSwimlanes();
  }

  mountMultipleBoardsSwitcher({
    fullPath: $boardApp.dataset.fullPath,
    rootPath: $boardApp.dataset.boardsEndpoint,
    recentBoardsEndpoint: $boardApp.dataset.recentBoardsEndpoint,
  });
};
