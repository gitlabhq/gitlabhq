/* eslint-disable one-var, quote-props, comma-dangle, space-before-function-paren, import/newline-after-import, no-multi-spaces, max-len */
/* global Vue */
/* global BoardService */

function requireAll(context) { return context.keys().map(context); }

window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
window.Sortable = require('vendor/Sortable');
requireAll(require.context('./models',   true, /^\.\/.*\.(js|es6)$/));
requireAll(require.context('./stores',   true, /^\.\/.*\.(js|es6)$/));
requireAll(require.context('./services', true, /^\.\/.*\.(js|es6)$/));
requireAll(require.context('./mixins',   true, /^\.\/.*\.(js|es6)$/));
requireAll(require.context('./filters',  true, /^\.\/.*\.(js|es6)$/));
require('./components/board');
require('./components/board_sidebar');
require('./components/new_list_dropdown');
require('./components/modal/index');
const backlogHelp = require('./components/boards_backlog_help');
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
      backlogHelp,
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
      detailIssue: Store.detail
    },
    computed: {
      detailIssueVisible () {
        return Object.keys(this.detailIssue.issue).length;
      },
      hideHelp() {
        if (this.loading) return false;

        return !this.state.helpHidden;
      },
    },
    created () {
      gl.boardService = new BoardService(this.endpoint, this.bulkUpdatePath, this.boardId);
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
    el: document.getElementById('js-boards-search'),
    data: {
      filters: Store.state.filters
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
});
