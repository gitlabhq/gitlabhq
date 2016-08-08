(() => {
  const BoardDelete = Vue.extend({
    props: {
      list: Object
    },
    methods: {
      deleteBoard: function () {
        $(this.$el).tooltip('destroy');

        if (confirm('Are you sure you want to delete this list?')) {
          this.list.destroy();
        }
      }
    }
  });

  Vue.component('board-delete', BoardDelete);
})();
