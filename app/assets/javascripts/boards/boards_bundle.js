/* eslint-disable one-var, quote-props, comma-dangle, space-before-function-paren */
/* global BoardService */
/* global Flash */

import Vue from 'vue';
import VueResource from 'vue-resource';
import FilteredSearchBoards from './filtered_search_boards';
import eventHub from './eventhub';
import './models/issue';
import './models/label';
import './models/list';
import './models/milestone';
import './models/assignee';
import './stores/boards_store';
import './stores/modal_store';
import './services/board_service';
import './mixins/modal_mixins';
import './mixins/sortable_default_options';
import './filters/due_date_filters';
import './components/board';
import './components/board_sidebar';
import './components/new_list_dropdown';
import './components/modal/index';
import '../vue_shared/vue_resource_interceptor';

import './components/boards_selector';
import collapseIcon from './icons/fullscreen_collapse.svg';
import expandIcon from './icons/fullscreen_expand.svg';

Vue.use(VueResource);

$(() => {
  const $boardApp = document.getElementById('board-app');
  const Store = gl.issueBoards.BoardsStore;
  const ModalStore = gl.issueBoards.ModalStore;
  const issueBoardsContent = document.querySelector('.content-wrapper > .js-focus-mode-board');

  window.gl = window.gl || {};

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  Store.create();

  // hack to allow sidebar scripts like milestone_select manipulate the BoardsStore
  gl.issueBoards.boardStoreIssueSet = (...args) => Vue.set(Store.detail.issue, ...args);
  gl.issueBoards.boardStoreIssueDelete = (...args) => Vue.delete(Store.detail.issue, ...args);

  gl.IssueBoardsApp = new Vue({
    el: $boardApp,
    components: {
      'board': gl.issueBoards.Board,
      'board-sidebar': gl.issueBoards.BoardSidebar,
      'board-add-issues-modal': gl.issueBoards.IssuesModal,
    },
    data: {
      state: Store.state,
      loading: true,
      endpoint: $boardApp.dataset.endpoint,
      boardId: $boardApp.dataset.boardId,
      disabled: $boardApp.dataset.disabled === 'true',
      issueLinkBase: $boardApp.dataset.issueLinkBase,
      rootPath: $boardApp.dataset.rootPath,
      bulkUpdatePath: $boardApp.dataset.bulkUpdatePath,
      detailIssue: Store.detail,
      milestoneTitle: $boardApp.dataset.boardMilestoneTitle,
      defaultAvatar: $boardApp.dataset.defaultAvatar,
    },
    computed: {
      detailIssueVisible () {
        return Object.keys(this.detailIssue.issue).length;
      },
    },
    created () {
      if (this.milestoneTitle) {
        const milestoneTitleParam = `milestone_title=${this.milestoneTitle}`;

        Store.filter.path = [milestoneTitleParam].concat(
          Store.filter.path.split('&').filter(param => param.match(/^milestone_title=(.*)$/g) === null)
        ).join('&');

        Store.updateFiltersUrl(true);
      }

      gl.boardService = new BoardService(this.endpoint, this.bulkUpdatePath, this.boardId);
      Store.rootPath = this.endpoint;

      this.filterManager = new FilteredSearchBoards(Store.filter, true, [(this.milestoneTitle ? 'milestone' : null)]);
      this.filterManager.setup();

      // Listen for updateTokens event
      eventHub.$on('updateTokens', this.updateTokens);
    },
    beforeDestroy() {
      eventHub.$off('updateTokens', this.updateTokens);
    },
    mounted () {
      Store.disabled = this.disabled;
      gl.boardService.all()
        .then(response => response.json())
        .then((resp) => {
          resp.forEach((board) => {
            const list = Store.addList(board, this.defaultAvatar);

            if (list.type === 'closed') {
              list.position = Infinity;
              list.label = { description: 'Shows all closed issues. Moving an issue to this list closes it' };
            } else if (list.type === 'backlog') {
              list.position = -1;
            }
          });

          this.state.lists = _.sortBy(this.state.lists, 'position');

          Store.addBlankState();
          this.loading = false;
        })
        .catch(() => new Flash('An error occurred. Please try again.'));
    },
    methods: {
      updateTokens() {
        this.filterManager.updateTokens();
      }
    },
  });

  gl.IssueBoardsSearch = new Vue({
    el: document.getElementById('js-add-list'),
    data: {
      filters: Store.state.filters,
      milestoneTitle: $boardApp.dataset.boardMilestoneTitle,
    },
    mounted () {
      gl.issueBoards.newListDropdownInit();
    },
  });

  gl.IssueBoardsModalAddBtn = new Vue({
    mixins: [gl.issueBoards.ModalMixins],
    el: document.getElementById('js-add-issues-btn'),
    data: {
      modal: ModalStore.store,
      store: Store.state,
      isFullscreen: false,
      focusModeAvailable: gl.utils.convertPermissionToBoolean($boardApp.dataset.focusModeAvailable),
    },
    watch: {
      disabled() {
        this.updateTooltip();
      },
    },
    computed: {
      disabled() {
        return !this.store.lists.filter(list => !list.preset).length;
      },
      tooltipTitle() {
        if (this.disabled) {
          return 'Please add a list to your board first';
        }

        return '';
      },
    },
    methods: {
      updateTooltip() {
        const $tooltip = $(this.$refs.addIssuesButton);

        this.$nextTick(() => {
          if (this.disabled) {
            $tooltip.tooltip();
          } else {
            $tooltip.tooltip('destroy');
          }
        });
      },
      openModal() {
        if (!this.disabled) {
          this.toggleModal(true);
        }
      },
      toggleFocusMode() {
        if (!this.focusModeAvailable) { return; }

        $(this.$refs.toggleFocusModeButton).tooltip('hide');
        issueBoardsContent.classList.toggle('is-focused');

        this.isFullscreen = !this.isFullscreen;
      },
    },
    mounted() {
      this.updateTooltip();
    },
    template: `
      <div class="board-extra-actions">
        <button
          class="btn btn-create prepend-left-10"
          type="button"
          data-placement="bottom"
          ref="addIssuesButton"
          :class="{ 'disabled': disabled }"
          :title="tooltipTitle"
          :aria-disabled="disabled"
          @click="openModal">
          Add issues
        </button>
        <a
          href="#"
          class="btn btn-default has-tooltip prepend-left-10"
          role="button"
          aria-label="Toggle focus mode"
          title="Toggle focus mode"
          ref="toggleFocusModeButton"
          v-if="focusModeAvailable"
          @click="toggleFocusMode">
          <span v-show="isFullscreen">
            ${collapseIcon}
          </span>
          <span v-show="!isFullscreen">
            ${expandIcon}
          </span>
        </a>
      </div>
    `,
  });

  gl.IssueboardsSwitcher = new Vue({
    el: '#js-multiple-boards-switcher',
    components: {
      'boards-selector': gl.issueBoards.BoardsSelector,
    }
  });
});
