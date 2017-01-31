/* eslint-disable one-var, quote-props, comma-dangle, space-before-function-paren */
/* global Vue */
/* global BoardService */

//= require vue
//= require vue-resource
//= require Sortable
//= require masonry
//= require_tree ./models
//= require_tree ./stores
//= require_tree ./services
//= require_tree ./mixins
//= require_tree ./filters
//= require ./components/board
//= require ./components/board_sidebar
//= require ./components/new_list_dropdown
//= require ./components/modal/index
//= require ./vue_resource_interceptor

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
      detailIssue: Store.detail
    },
    computed: {
      detailIssueVisible () {
        return Object.keys(this.detailIssue.issue).length;
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

          if (this.state.lists.length > 0) {
            ModalStore.store.selectedList = this.state.lists[0];
          }
        });
    }
  });

  gl.IssueBoardsSearch = new Vue({
    el: '#js-boards-search',
    data: {
      filters: Store.state.filters
    },
    mounted () {
      gl.issueBoards.newListDropdownInit();
    }
  });

  gl.IssueBoardsModalAddBtn = new Vue({
    mixins: [gl.issueBoards.ModalMixins],
    el: '#js-add-issues-btn',
    data: {
      modal: ModalStore.store,
      store: Store.state,
    },
    computed: {
      disabled() {
        return Store.shouldAddBlankState();
      },
    },
    template: `
      <button
        class="btn btn-create pull-right prepend-left-10 has-tooltip"
        type="button"
        :disabled="disabled"
        @click="toggleModal(true)">
        Add issues
      </button>
    `,
  });
});
