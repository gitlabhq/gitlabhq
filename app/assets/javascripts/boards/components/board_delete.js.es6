(() => {
  const BoardDelete = Vue.extend({
    props: {
      list: Object
    },
    methods: {
      deleteBoard: function (e) {
        e.stopImmediatePropagation();
        $(this.$el).tooltip('hide');

        if (confirm('Are you sure you want to delete this list?')) {
          this.list.destroy();
        }
      }
    }
  });

  Vue.component('board-delete', BoardDelete);
})();
