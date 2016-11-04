/* eslint-disable */
//= require vue
//= require vue-resource
//= require Sortable
//= require_tree ./models
//= require_tree ./stores
//= require_tree ./services
//= require_tree ./mixins
//= require_tree ./filters
//= require ./components/board
//= require ./components/board_sidebar
//= require ./components/new_list_dropdown
//= require ./vue_resource_interceptor

$(() => {
  const $boardApp = document.getElementById('board-app'),
        Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  Store.create();

  gl.IssueBoardsApp = new Vue({
    el: $boardApp,
    components: {
      'board': gl.issueBoards.Board,
      'board-sidebar': gl.issueBoards.BoardSidebar
    },
    data: {
      state: Store.state,
      loading: true,
      endpoint: $boardApp.dataset.endpoint,
      boardId: $boardApp.dataset.boardId,
      disabled: $boardApp.dataset.disabled === 'true',
      issueLinkBase: $boardApp.dataset.issueLinkBase,
      detailIssue: Store.detail
    },
    computed: {
      detailIssueVisible () {
        return Object.keys(this.detailIssue.issue).length;
      },
    },
    created () {
      gl.boardService = new BoardService(this.endpoint, this.boardId);
    },
    mounted () {
      Store.disabled = this.disabled;
      gl.boardService.all()
        .then((resp) => {
          resp.json().forEach((board) => {
            const list = Store.addList(board);

            if (list.type === 'done') {
              list.position = Infinity;
            } else if (list.type === 'backlog') {
              list.position = -1;
            }
          });

          Store.addBlankState();
          this.loading = false;
        });
    }
  });

  gl.IssueBoardsSearch = new Vue({
    el: '#js-boards-seach',
    data: {
      filters: Store.state.filters
    },
    mounted () {
      gl.issueBoards.newListDropdownInit();
    }
  });
});
