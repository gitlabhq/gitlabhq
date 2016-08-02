(() => {
  const BoardDelete = Vue.extend({
    props: {
      boardId: Number
    },
    methods: {
      deleteBoard: function () {
        $(this.$el).tooltip('destroy');

        if (confirm('Are you sure you want to delete this list?')) {
          BoardsStore.removeList(this.boardId);
        }
      }
    }
  });

  Vue.component('board-delete', BoardDelete);
})();
