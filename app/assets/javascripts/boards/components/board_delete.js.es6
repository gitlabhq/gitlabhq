(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardDelete = Vue.extend({
    props: {
      list: Object
    },
    methods: {
      deleteBoard (e) {
        e.stopImmediatePropagation();
        $(this.$el).tooltip('hide');

        if (confirm('Are you sure you want to delete this list?')) {
          this.list.destroy();
        }
      }
    }
  });
})();
