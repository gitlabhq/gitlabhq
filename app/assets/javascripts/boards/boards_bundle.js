/* eslint-disable one-var, quote-props, comma-dangle, space-before-function-paren */
/* global Vue */
/* global BoardService */

import FilteredSearchBoards from './filtered_search_boards';

window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
require('./models/issue');
require('./models/label');
require('./models/list');
require('./models/milestone');
require('./models/user');
require('./stores/boards_store');
require('./stores/modal_store');
require('./services/board_service');
require('./mixins/modal_mixins');
require('./mixins/sortable_default_options');
require('./filters/due_date_filters');
require('./components/board');
require('./components/boards_selector');
require('./components/board_sidebar');
require('./components/new_list_dropdown');
require('./components/modal/index');
require('../vue_shared/vue_resource_interceptor');

$(() => {
  const $boardApp = document.getElementById('board-app');
  const Store = gl.issueBoards.BoardsStore;
  const ModalStore = gl.issueBoards.ModalStore;

  window.gl = window.gl || {};

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  Store.create();

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
    },
    computed: {
      detailIssueVisible () {
        return Object.keys(this.detailIssue.issue).length;
      },
    },
    created () {
      if (this.milestoneTitle) {
        const milestoneTitleParam = `milestone_title=${this.milestoneTitle}`;
        let splitPath = Store.filter.path.split('&').filter((param) => {
          return param.match(/^milestone_title=(.*)$/g) === null;
        });

        splitPath = [milestoneTitleParam].concat(splitPath);
        Store.filter.path = splitPath.join('&');

        Store.updateFiltersUrl();
      }

      gl.boardService = new BoardService(this.endpoint, this.bulkUpdatePath, this.boardId);

      gl.boardsFilterManager = new FilteredSearchBoards(Store.filter, true, [(this.milestoneTitle ? 'milestone' : null)]);
    },
    mounted () {
      Store.disabled = this.disabled;
      gl.boardService.all()
        .then((resp) => {
          resp.json().forEach((board) => {
            const list = Store.addList(board);

            if (list.type === 'done') {
              list.position = Infinity;
            }
          });

          this.state.lists = _.sortBy(this.state.lists, 'position');

          Store.addBlankState();
          this.loading = false;
        });
    }
  });

  gl.IssueBoardsSearch = new Vue({
    el: document.getElementById('js-add-list'),
    data: {
      filters: Store.state.filters,
      milestoneTitle: $boardApp.dataset.boardMilestoneTitle,
    },
    mounted () {
      gl.issueBoards.newListDropdownInit();
    }
  });

  gl.IssueBoardsModalAddBtn = new Vue({
    mixins: [gl.issueBoards.ModalMixins],
    el: document.getElementById('js-add-issues-btn'),
    data: {
      modal: ModalStore.store,
      store: Store.state,
    },
    watch: {
      disabled() {
        this.updateTooltip();
      },
    },
    computed: {
      disabled() {
        return !this.store.lists.filter(list => list.type !== 'blank' && list.type !== 'done').length;
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
        const $tooltip = $(this.$el);

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
    },
    mounted() {
      this.updateTooltip();
    },
    template: `
      <button
        class="btn btn-create pull-right prepend-left-10"
        type="button"
        data-placement="bottom"
        :class="{ 'disabled': disabled }"
        :title="tooltipTitle"
        :aria-disabled="disabled"
        @click="openModal">
        Add issues
      </button>
    `,
  });

  gl.IssueboardsSwitcher = new Vue({
    el: '#js-multiple-boards-switcher',
    components: {
      'boards-selector': gl.issueBoards.BoardsSelector,
    }
  });
});
