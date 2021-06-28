import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import PortalVue from 'portal-vue';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mapActions, mapGetters } from 'vuex';

import 'ee_else_ce/boards/models/issue';
import 'ee_else_ce/boards/models/list';
import BoardSidebar from 'ee_else_ce/boards/components/board_sidebar';
import initNewListDropdown from 'ee_else_ce/boards/components/new_list_dropdown';
import {
  setWeightFetchingState,
  setEpicFetchingState,
  getMilestoneTitle,
} from 'ee_else_ce/boards/ee_functions';
import toggleEpicsSwimlanes from 'ee_else_ce/boards/toggle_epics_swimlanes';
import toggleLabels from 'ee_else_ce/boards/toggle_labels';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import BoardContent from '~/boards/components/board_content.vue';
import './models/label';
import './models/assignee';
import '~/boards/models/milestone';
import '~/boards/models/project';
import '~/boards/filters/due_date_filters';
import { issuableTypes } from '~/boards/constants';
import eventHub from '~/boards/eventhub';
import FilteredSearchBoards from '~/boards/filtered_search_boards';
import store from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';
import toggleFocusMode from '~/boards/toggle_focus';
import createDefaultClient from '~/lib/graphql';
import {
  NavigationType,
  convertObjectPropsToCamelCase,
  parseBoolean,
} from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import sidebarEventHub from '~/sidebar/event_hub';
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

  if (!gon?.features?.graphqlBoardLists) {
    boardsStore.create();
    boardsStore.setTimeTrackingLimitToHours($boardApp.dataset.timeTrackingLimitToHours);
  }

  // eslint-disable-next-line @gitlab/no-runtime-template-compiler
  issueBoardsApp = new Vue({
    el: $boardApp,
    components: {
      BoardContent,
      BoardSidebar,
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
        state: boardsStore.state,
        loading: 0,
        boardsEndpoint: $boardApp.dataset.boardsEndpoint,
        recentBoardsEndpoint: $boardApp.dataset.recentBoardsEndpoint,
        listsEndpoint: $boardApp.dataset.listsEndpoint,
        disabled: parseBoolean($boardApp.dataset.disabled),
        bulkUpdatePath: $boardApp.dataset.bulkUpdatePath,
        detailIssue: boardsStore.detail,
        parent: $boardApp.dataset.parent,
      };
    },
    computed: {
      ...mapGetters(['shouldUseGraphQL']),
      detailIssueVisible() {
        return Object.keys(this.detailIssue.issue).length;
      },
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
      boardsStore.setEndpoints({
        boardsEndpoint: this.boardsEndpoint,
        recentBoardsEndpoint: this.recentBoardsEndpoint,
        listsEndpoint: this.listsEndpoint,
        bulkUpdatePath: this.bulkUpdatePath,
        boardId: $boardApp.dataset.boardId,
        fullPath: $boardApp.dataset.fullPath,
      });
      boardsStore.rootPath = this.boardsEndpoint;

      eventHub.$on('updateTokens', this.updateTokens);
      eventHub.$on('newDetailIssue', this.updateDetailIssue);
      eventHub.$on('clearDetailIssue', this.clearDetailIssue);
      sidebarEventHub.$on('toggleSubscription', this.toggleSubscription);
      eventHub.$on('initialBoardLoad', this.initialBoardLoad);
    },
    beforeDestroy() {
      eventHub.$off('updateTokens', this.updateTokens);
      eventHub.$off('newDetailIssue', this.updateDetailIssue);
      eventHub.$off('clearDetailIssue', this.clearDetailIssue);
      sidebarEventHub.$off('toggleSubscription', this.toggleSubscription);
      eventHub.$off('initialBoardLoad', this.initialBoardLoad);
    },
    mounted() {
      this.filterManager = new FilteredSearchBoards(boardsStore.filter, true, boardsStore.cantEdit);

      this.filterManager.setup();

      this.performSearch();

      boardsStore.disabled = this.disabled;

      if (!this.shouldUseGraphQL) {
        this.initialBoardLoad();
      }
    },
    methods: {
      ...mapActions(['setInitialBoardData', 'performSearch', 'setError']),
      initialBoardLoad() {
        boardsStore
          .all()
          .then((res) => res.data)
          .then((lists) => {
            lists.forEach((list) => boardsStore.addList(list));
            this.loading = false;
          })
          .catch((error) => {
            this.setError({
              error,
              message: __('An error occurred while fetching the board lists. Please try again.'),
            });
          });
      },
      updateTokens() {
        this.filterManager.updateTokens();
      },
      updateDetailIssue(newIssue, multiSelect = false) {
        const { sidebarInfoEndpoint } = newIssue;
        if (sidebarInfoEndpoint && newIssue.subscribed === undefined) {
          newIssue.setFetchingState('subscriptions', true);
          setWeightFetchingState(newIssue, true);
          setEpicFetchingState(newIssue, true);
          boardsStore
            .getIssueInfo(sidebarInfoEndpoint)
            .then((res) => res.data)
            .then((data) => {
              const {
                subscribed,
                totalTimeSpent,
                timeEstimate,
                humanTimeEstimate,
                humanTotalTimeSpent,
                weight,
                epic,
                assignees,
              } = convertObjectPropsToCamelCase(data);

              newIssue.setFetchingState('subscriptions', false);
              setWeightFetchingState(newIssue, false);
              setEpicFetchingState(newIssue, false);
              newIssue.updateData({
                humanTimeSpent: humanTotalTimeSpent,
                timeSpent: totalTimeSpent,
                humanTimeEstimate,
                timeEstimate,
                subscribed,
                weight,
                epic,
                assignees,
              });
            })
            .catch(() => {
              newIssue.setFetchingState('subscriptions', false);
              setWeightFetchingState(newIssue, false);
              this.setError({ message: __('An error occurred while fetching sidebar data') });
            });
        }

        if (multiSelect) {
          boardsStore.toggleMultiSelect(newIssue);

          if (boardsStore.detail.issue) {
            boardsStore.clearDetailIssue();
            return;
          }

          return;
        }

        boardsStore.setIssueDetail(newIssue);
      },
      clearDetailIssue(multiSelect = false) {
        if (multiSelect) {
          boardsStore.clearMultiSelect();
        }
        boardsStore.clearDetailIssue();
      },
      toggleSubscription(id) {
        const { issue } = boardsStore.detail;
        if (issue.id === id && issue.toggleSubscriptionEndpoint) {
          issue.setFetchingState('subscriptions', true);
          boardsStore
            .toggleIssueSubscription(issue.toggleSubscriptionEndpoint)
            .then(() => {
              issue.setFetchingState('subscriptions', false);
              issue.updateData({
                subscribed: !issue.subscribed,
              });
            })
            .catch(() => {
              issue.setFetchingState('subscriptions', false);
              this.setError({
                message: __('An error occurred when toggling the notification subscription'),
              });
            });
        }
      },
      getNodes(data) {
        return data[this.parent]?.board?.lists.nodes;
      },
    },
  });

  // eslint-disable-next-line no-new, @gitlab/no-runtime-template-compiler
  new Vue({
    el: document.getElementById('js-add-list'),
    data() {
      return {
        filters: boardsStore.state.filters,
        ...getMilestoneTitle($boardApp),
      };
    },
    mounted() {
      initNewListDropdown();
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

  boardConfigToggle(boardsStore);

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
