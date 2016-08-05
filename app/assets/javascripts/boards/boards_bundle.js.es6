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
  gl.boardService = new BoardService($('#board-app').data('endpoint'));

  if (gl.IssueBoardsApp) {
    gl.IssueBoardsApp.$destroy(true);
  }

  gl.IssueBoardsApp = new Vue({
    el: '#board-app',
    data: {
      state: BoardsStore.state
    },
    init: function () {
      BoardsStore.create();
    },
    ready: function () {
      gl.boardService.all()
        .then((resp) => {
          const boards = resp.json();

          boards.forEach((board) => {
            const list = BoardsStore.new(board, false);

            if (list.type === 'done') {
              list.position = 9999999;
            } else if (list.type === 'backlog') {
              list.position = -1;
            }
          });

          BoardsStore.addBlankState();
        });
    }
  });
});
