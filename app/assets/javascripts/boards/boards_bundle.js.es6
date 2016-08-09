//= require vue
//= require vue-resource
//= require Sortable
//= require_tree ./models
//= require_tree ./stores
//= require_tree ./services
//= require_tree ./mixins
//= require_tree ./components

$(function () {
  if (!window.gl) {
    window.gl = {};
  }

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  gl.IssueBoardsApp = new Vue({
    el: '#board-app',
    props: {
      disabled: Boolean,
      endpoint: String,
      issueLinkBase: String
    },
    data: {
      state: BoardsStore.state,
      loading: true
    },
    init: function () {
      BoardsStore.create();
    },
    created: function () {
      this.loading = true;
      gl.boardService = new BoardService(this.endpoint);
    },
    ready: function () {
      BoardsStore.disabled = this.disabled;
      gl.boardService.all()
        .then((resp) => {
          const boards = resp.json();

          boards.forEach((board) => {
            const list = BoardsStore.addList(board);

            if (list.type === 'done') {
              list.position = 9999999;
            } else if (list.type === 'backlog') {
              list.position = -1;
            }
          });

          BoardsStore.addBlankState();
          this.loading = false;
        });
    }
  });
});
