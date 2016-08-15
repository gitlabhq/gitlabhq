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
  const $boardApp = $('#board-app');

  window.gl = window.gl || {};

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  gl.IssueBoardsApp = new Vue({
    el: $boardApp.get(0),
    components: {
      'board': gl.issueBoards.Board
    },
    data: {
      state: gl.issueBoards.BoardsStore.state,
      loading: true,
      endpoint: $boardApp.data('endpoint'),
      disabled: $boardApp.data('disabled'),
      issueLinkBase: $boardApp.data('issue-link-base')
    },
    init () {
      gl.issueBoards.BoardsStore.create();
    },
    created () {
      this.loading = true;
      gl.boardService = new BoardService(this.endpoint);

      $boardApp
        .removeAttr('data-endpoint')
        .removeAttr('data-disabled')
        .removeAttr('data-issue-link-base');
    },
    ready () {
      gl.issueBoards.BoardsStore.disabled = this.disabled;
      gl.boardService.all()
        .then((resp) => {
          const boards = resp.json();

          for (let i = 0, boardsLength = boards.length; i < boardsLength; i++) {
            const board = boards[i],
                  list = gl.issueBoards.BoardsStore.addList(board);

            if (list.type === 'done') {
              list.position = Infinity;
            } else if (list.type === 'backlog') {
              list.position = -1;
            }
          }

          gl.issueBoards.BoardsStore.addBlankState();
          this.loading = false;
        });
    }
  });
});
