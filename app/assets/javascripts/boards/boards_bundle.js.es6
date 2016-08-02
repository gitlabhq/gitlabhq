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

          // Add blank state board
          if (boards.length === 2) {
            boards.splice(1, 0, {
              id: 'blank',
              title: 'Welcome to your Issue Board!',
              index: 1
            });
          }

          boards.forEach((board) => {
            BoardsStore.new(board);
          });
        });
    }
  });
});
