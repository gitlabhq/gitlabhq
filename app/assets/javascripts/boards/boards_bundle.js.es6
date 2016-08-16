//= require vue
//= require vue-resource
//= require Sortable
//= require_tree ./models
//= require_tree ./stores
//= require_tree ./services
//= require_tree ./mixins
//= require ./components/board
//= require ./components/new_list_dropdown

$(() => {
  const $boardApp = document.getElementById('board-app'),
        Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  gl.IssueBoardsApp = new Vue({
    el: $boardApp,
    components: {
      'board': gl.issueBoards.Board
    },
    data: {
      state: Store.state,
      loading: true,
      endpoint: $boardApp.dataset.endpoint,
      disabled: $boardApp.dataset.disabled === 'true',
      issueLinkBase: $boardApp.dataset.issueLinkBase
    },
    init () {
      gl.issueBoards.BoardsStore.create();
    },
    created () {
      this.loading = true;
      gl.boardService = new BoardService(this.endpoint);
    },
    ready () {
      Store.disabled = this.disabled;
      gl.boardService.all()
        .then((resp) => {
          const boards = resp.json();

          for (let i = 0, boardsLength = boards.length; i < boardsLength; i++) {
            const board = boards[i],
                  list = Store.addList(board);

            if (list.type === 'done') {
              list.position = Infinity;
            } else if (list.type === 'backlog') {
              list.position = -1;
            }
          }

          Store.addBlankState();
          this.loading = false;
        });
    }
  });
});
