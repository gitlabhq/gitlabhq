import $ from 'jquery';
import Vue from 'vue';
import { mapActions } from 'vuex';

import 'ee_else_ce/boards/models/issue';
import 'ee_else_ce/boards/models/list';
import BoardContent from '~/boards/components/board_content.vue';
import BoardSidebar from 'ee_else_ce/boards/components/board_sidebar';
import initNewListDropdown from 'ee_else_ce/boards/components/new_list_dropdown';
import boardConfigToggle from 'ee_else_ce/boards/config_toggle';
import toggleLabels from 'ee_else_ce/boards/toggle_labels';
import toggleEpicsSwimlanes from 'ee_else_ce/boards/toggle_epics_swimlanes';
import {
  setPromotionState,
  setWeigthFetchingState,
  setEpicFetchingState,
  getMilestoneTitle,
  getBoardsModalData,
} from 'ee_else_ce/boards/ee_functions';

import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import Flash from '~/flash';
import { __ } from '~/locale';
import './models/label';
import './models/assignee';
import { BoardType } from './constants';

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
} from '~/lib/utils/common_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import mountMultipleBoardsSwitcher from './mount_multiple_boards_switcher';
import projectBoardQuery from './queries/project_board.query.graphql';
import groupQuery from './queries/group_board.query.graphql';

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
      Board: () =>
        window?.gon?.features?.sfcIssueBoards
          ? import('ee_else_ce/boards/components/board_column.vue')
          : /**
             * Please have a look at, we are moving to the SFC soon:
             * https://gitlab.com/gitlab-org/gitlab/-/issues/212300
             * @deprecated
             */
            import('ee_else_ce/boards/components/board'),
      BoardSidebar,
      BoardAddIssuesModal,
      BoardSettingsSidebar: () =>
        import('ee_component/boards/components/board_settings_sidebar.vue'),
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
        boardId: $boardApp.dataset.boardId,
        disabled: parseBoolean($boardApp.dataset.disabled),
        issueLinkBase: $boardApp.dataset.issueLinkBase,
        rootPath: $boardApp.dataset.rootPath,
        bulkUpdatePath: $boardApp.dataset.bulkUpdatePath,
        detailIssue: boardsStore.detail,
        parent: $boardApp.dataset.parent,
      };
    },
    computed: {
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
        boardId: this.boardId,
        fullPath: $boardApp.dataset.fullPath,
      };
      this.setEndpoints(endpoints);
      boardsStore.setEndpoints(endpoints);
      boardsStore.rootPath = this.boardsEndpoint;

      eventHub.$on('updateTokens', this.updateTokens);
      eventHub.$on('newDetailIssue', this.updateDetailIssue);
      eventHub.$on('clearDetailIssue', this.clearDetailIssue);
      sidebarEventHub.$on('toggleSubscription', this.toggleSubscription);
    },
    beforeDestroy() {
      eventHub.$off('updateTokens', this.updateTokens);
      eventHub.$off('newDetailIssue', this.updateDetailIssue);
      eventHub.$off('clearDetailIssue', this.clearDetailIssue);
      sidebarEventHub.$off('toggleSubscription', this.toggleSubscription);
    },
    mounted() {
      this.filterManager = new FilteredSearchBoards(boardsStore.filter, true, boardsStore.cantEdit);
      this.filterManager.setup();

      boardsStore.disabled = this.disabled;

      if (gon.features.graphqlBoardLists) {
        this.$apollo.addSmartQuery('lists', {
          query() {
            return this.parent === BoardType.group ? groupQuery : projectBoardQuery;
          },
          variables() {
            return {
              fullPath: this.state.endpoints.fullPath,
              boardId: `gid://gitlab/Board/${this.boardId}`,
            };
          },
          update(data) {
            return this.getNodes(data);
          },
          result({ data, error }) {
            if (error) {
              throw error;
            }

            const lists = this.getNodes(data);

            lists.forEach(list =>
              boardsStore.addList({
                ...list,
                id: getIdFromGraphQLId(list.id),
              }),
            );

            boardsStore.addBlankState();
            setPromotionState(boardsStore);
          },
          error() {
            Flash(__('An error occurred while fetching the board lists. Please try again.'));
          },
        });
      } else {
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
      }
    },
    methods: {
      ...mapActions(['setEndpoints']),
      updateTokens() {
        this.filterManager.updateTokens();
      },
      updateDetailIssue(newIssue, multiSelect = false) {
        const { sidebarInfoEndpoint } = newIssue;
        if (sidebarInfoEndpoint && newIssue.subscribed === undefined) {
          newIssue.setFetchingState('subscriptions', true);
          setWeigthFetchingState(newIssue, true);
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
              setWeigthFetchingState(newIssue, false);
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
              setWeigthFetchingState(newIssue, false);
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

  if (issueBoardsModal) {
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
        tooltipTitle() {
          if (this.disabled) {
            return __('Please add a list to your board first');
          }

          return '';
        },
      },
      watch: {
        disabled() {
          this.updateTooltip();
        },
      },
      mounted() {
        this.updateTooltip();
      },
      methods: {
        updateTooltip() {
          const $tooltip = $(this.$refs.addIssuesButton);

          this.$nextTick(() => {
            if (this.disabled) {
              $tooltip.tooltip();
            } else {
              $tooltip.tooltip('dispose');
            }
          });
        },
        openModal() {
          if (!this.disabled) {
            this.toggleModal(true);
          }
        },
      },
      template: `
        <div class="board-extra-actions">
          <button
            class="btn btn-success prepend-left-10"
            type="button"
            data-placement="bottom"
            ref="addIssuesButton"
            :class="{ 'disabled': disabled }"
            :title="tooltipTitle"
            :aria-disabled="disabled"
            v-if="canAdminList"
            @click="openModal">
            Add issues
          </button>
        </div>
      `,
    });
  }

  toggleFocusMode(ModalStore, boardsStore);
  toggleLabels();
  toggleEpicsSwimlanes();
  mountMultipleBoardsSwitcher();
};
