//= require vue
//= require vue-resource
//= require Sortable
//= require_tree ./models
//= require_tree ./stores
//= require_tree ./services
//= require_tree ./components

$(function () {
  window.service = new BoardService($('#board-app').data('endpoint'));

  new Vue({
    el: '#board-app',
    data: {
      state: BoardsStore.state
    },
    ready: function () {
      service.all()
        .then((resp) => {
          const boards = resp.json();

          boards.forEach((board) => {
            const list = BoardsStore.new(board, false);

            if (list.type === 'done') {
              list.position = 9999999;
            }
          });

          BoardsStore.addBlankState();
        });
    }
  });
});
