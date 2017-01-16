/* eslint-disable comma-dangle, space-before-function-paren, no-alert */
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardDelete = Vue.extend({
    template: `
      <button
        class="board-delete has-tooltip pull-right"
        type="button"
        title="Delete list"
        aria-label="Delete list"
        @click.stop="deleteBoard"
        data-placement="bottom">
        <i class="fa fa-trash"></i>
      </button>
    `,
    props: {
      list: Object
    },
    methods: {
      deleteBoard () {
        $(this.$el).tooltip('hide');

        if (confirm('Are you sure you want to delete this list?')) {
          this.list.destroy();
        }
      }
    }
  });
})();
