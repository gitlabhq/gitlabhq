import Vue from 'vue';
import { mapActions, mapGetters } from 'vuex';

import 'ee_else_ce/boards/models/issue';
import 'ee_else_ce/boards/models/list';
import BoardSidebar from 'ee_else_ce/boards/components/board_sidebar';
import initNewListDropdown from 'ee_else_ce/boards/components/new_list_dropdown';
import boardConfigToggle from 'ee_else_ce/boards/config_toggle';
import toggleLabels from 'ee_else_ce/boards/toggle_labels';
import toggleEpicsSwimlanes from 'ee_else_ce/boards/toggle_epics_swimlanes';
import {
  setPromotionState,
  setWeightFetchingState,
  setEpicFetchingState,
  getMilestoneTitle,
  getBoardsModalData,
} from 'ee_else_ce/boards/ee_functions';

import VueApollo from 'vue-apollo';
import BoardContent from '~/boards/components/board_content.vue';
import BoardExtraActions from '~/boards/components/board_extra_actions.vue';
import createDefaultClient from '~/lib/graphql';
import { deprecatedCreateFlash as Flash } from '~/flash';
import { __ } from '~/locale';
import './models/label';
import './models/assignee';

import toggleFocusMode from '~/boards/toggle_focus';
import FilteredSearchBoards from '~/boards/filtered_search_boards';
import eventHub from '~/boards/eventhub';
import sidebarEventHub from '~/sidebar/event_hub';
import '~/boards/models/milestone';
import '~/boards/models/project';
import store from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';
import ModalStore from '~/boards/stores/modal_store';
import modalMixin from '~/boards/mixins/modal_mixins';
import '~/boards/filters/due_date_filters';
import BoardAddIssuesModal from '~/boards/components/modal/index.vue';
import {
  NavigationType,
  convertObjectPropsToCamelCase,
  parseBoolean,
  urlParamsToObject,
} from '~/lib/utils/common_utils';
import mountMultipleBoardsSwitcher from './mount_multiple_boards_switcher';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

let issueBoardsApp;

export default () => {
  const $boardApp = document.getElementById('board-app');

  // check for browser back and trigger a hard reload to circumvent browser caching.
  window.addEventListener('pageshow', event => {
    const isNavTypeBackForward =
      window.performance && window.performance.navigation.type === NavigationType.TYPE_BACK_FORWARD;

    if (event.persisted || isNavTypeBackForward) {
      window.location.reload();
    }
  });

  if (issueBoardsApp) {
    issueBoardsApp.$destroy(true);
  }

  boardsStore.create();
  boardsStore.setTimeTrackingLimitToHours($boardApp.dataset.timeTrackingLimitToHours);

  issueBoardsApp = new Vue({
    el: $boardApp,
    components: {
      BoardContent,
      BoardSidebar,
      BoardAddIssuesModal,
      BoardSettingsSidebar: () => import('~/boards/components/board_settings_sidebar.vue'),
    },
    provide: {
      boardId: $boardApp.dataset.boardId,
      groupId: Number($boardApp.dataset.groupId),
      rootPath: $boardApp.dataset.rootPath,
      currentUserId: gon.current_user_id || null,
      canUpdate: $boardApp.dataset.canUpdate,
      labelsFetchPath: $boardApp.dataset.labelsFetchPath,
      labelsManagePath: $boardApp.dataset.labelsManagePath,
      labelsFilterBasePath: $boardApp.dataset.labelsFilterBasePath,
      timeTrackingLimitToHours: parseBoolean($boardApp.dataset.timeTrackingLimitToHours),
      weightFeatureAvailable: parseBoolean($boardApp.dataset.weightFeatureAvailable),
      boardWeight: $boardApp.dataset.boardWeight
        ? parseInt($boardApp.dataset.boardWeight, 10)
        : null,
      scopedLabelsAvailable: parseBoolean($boardApp.dataset.scopedLabels),
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
      ...mapGetters(['isSwimlanesOn', 'shouldUseGraphQL']),
      detailIssueVisible() {
        return Object.keys(this.detailIssue.issue).length;
      },
    },
    created() {
      const endpoints = {
        boardsEndpoint: this.boardsEndpoint,
        recentBoardsEndpoint: this.recentBoardsEndpoint,
        listsEndpoint: this.listsEndpoint,
        bulkUpdatePath: this.bulkUpdatePath,
        boardId: $boardApp.dataset.boardId,
        fullPath: $boardApp.dataset.fullPath,
      };
      this.setInitialBoardData({
        ...endpoints,
        boardType: this.parent,
        disabled: this.disabled,
        showPromotion: parseBoolean($boardApp.getAttribute('data-show-promotion')),
      });
      boardsStore.setEndpoints(endpoints);
      boardsStore.rootPath = this.boardsEndpoint;

      eventHub.$on('updateTokens', this.updateTokens);
      eventHub.$on('newDetailIssue', this.updateDetailIssue);
      eventHub.$on('clearDetailIssue', this.clearDetailIssue);
      sidebarEventHub.$on('toggleSubscription', this.toggleSubscription);
      eventHub.$on('performSearch', this.performSearch);
      eventHub.$on('initialBoardLoad', this.initialBoardLoad);
    },
    beforeDestroy() {
      eventHub.$off('updateTokens', this.updateTokens);
      eventHub.$off('newDetailIssue', this.updateDetailIssue);
      eventHub.$off('clearDetailIssue', this.clearDetailIssue);
      sidebarEventHub.$off('toggleSubscription', this.toggleSubscription);
      eventHub.$off('performSearch', this.performSearch);
      eventHub.$off('initialBoardLoad', this.initialBoardLoad);
    },
    mounted() {
      this.filterManager = new FilteredSearchBoards(
        boardsStore.filter,
        store,
        true,
        boardsStore.cantEdit,
      );
      this.filterManager.setup();

      this.performSearch();

      boardsStore.disabled = this.disabled;

      if (!this.shouldUseGraphQL) {
        this.initialBoardLoad();
      }
    },
    methods: {
      ...mapActions([
        'setInitialBoardData',
        'setFilters',
        'fetchEpicsSwimlanes',
        'resetIssues',
        'resetEpics',
        'fetchLists',
      ]),
      initialBoardLoad() {
        boardsStore
          .all()
          .then(res => res.data)
          .then(lists => {
            lists.forEach(list => boardsStore.addList(list));
            boardsStore.addBlankState();
            setPromotionState(boardsStore);
            this.loading = false;
          })
          .catch(() => {
            Flash(__('An error occurred while fetching the board lists. Please try again.'));
          });
      },
      updateTokens() {
        this.filterManager.updateTokens();
      },
      performSearch() {
        this.setFilters(convertObjectPropsToCamelCase(urlParamsToObject(window.location.search)));
        if (this.isSwimlanesOn) {
          this.resetEpics();
          this.resetIssues();
          this.fetchEpicsSwimlanes({});
        } else if (gon.features.graphqlBoardLists) {
          this.fetchLists();
          this.resetIssues();
        }
      },
      updateDetailIssue(newIssue, multiSelect = false) {
        const { sidebarInfoEndpoint } = newIssue;
        if (sidebarInfoEndpoint && newIssue.subscribed === undefined) {
          newIssue.setFetchingState('subscriptions', true);
          setWeightFetchingState(newIssue, true);
          setEpicFetchingState(newIssue, true);
          boardsStore
            .getIssueInfo(sidebarInfoEndpoint)
            .then(res => res.data)
            .then(data => {
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
              Flash(__('An error occurred while fetching sidebar data'));
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
              Flash(__('An error occurred when toggling the notification subscription'));
            });
        }
      },
      getNodes(data) {
        return data[this.parent]?.board?.lists.nodes;
      },
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: document.getElementById('js-add-list'),
    data: {
      filters: boardsStore.state.filters,
      ...getMilestoneTitle($boardApp),
    },
    mounted() {
      initNewListDropdown();
    },
  });

  boardConfigToggle(boardsStore);

  const issueBoardsModal = document.getElementById('js-add-issues-btn');

  if (issueBoardsModal && gon.features.addIssuesButton) {
    // eslint-disable-next-line no-new
    new Vue({
      el: issueBoardsModal,
      mixins: [modalMixin],
      data() {
        return {
          modal: ModalStore.store,
          store: boardsStore.state,
          ...getBoardsModalData(),
          canAdminList: this.$options.el.hasAttribute('data-can-admin-list'),
        };
      },
      computed: {
        disabled() {
          if (!this.store) {
            return true;
          }
          return !this.store.lists.filter(list => !list.preset).length;
        },
      },
      methods: {
        openModal() {
          if (!this.disabled) {
            this.toggleModal(true);
          }
        },
      },
      render(createElement) {
        return createElement(BoardExtraActions, {
          props: {
            canAdminList: this.$options.el.hasAttribute('data-can-admin-list'),
            openModal: this.openModal,
            disabled: this.disabled,
          },
        });
      },
    });
  }

  toggleFocusMode(ModalStore, boardsStore);
  toggleLabels();

  if (gon.features?.swimlanes) {
    toggleEpicsSwimlanes();
  }

  mountMultipleBoardsSwitcher();
};
