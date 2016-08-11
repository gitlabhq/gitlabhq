//= require vue
//= require vue-resource
//= require Sortable
//= require_tree ./models
//= require_tree ./stores
//= require_tree ./services
//= require_tree ./mixins
//= require_tree ./components

$(() => {
  const $boardApp = $('#board-app');

  if (!window.gl) {
    window.gl = {};
  }

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  gl.IssueBoardsApp = new Vue({
    el: $boardApp.get(0),
    data: {
      state: BoardsStore.state,
      loading: true,
      endpoint: $boardApp.data('endpoint'),
      disabled: $boardApp.data('disabled'),
      issueLinkBase: $boardApp.data('issue-link-base')
    },
    init () {
      BoardsStore.create();
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
      BoardsStore.disabled = this.disabled;
      gl.boardService.all()
        .then((resp) => {
          const boards = resp.json();

          for (let i = 0, boardsLength = boards.length; i < boardsLength; i++) {
            const board = boards[i],
                  list = BoardsStore.addList(board);

            if (list.type === 'done') {
              list.position = Infinity;
            } else if (list.type === 'backlog') {
              list.position = -1;
            }
          }

          BoardsStore.addBlankState();
          this.loading = false;
        });
    }
  });
});
