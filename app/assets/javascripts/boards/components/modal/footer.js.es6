/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalFooter = Vue.extend({
    data() {
      return Store.modal;
    },
    methods: {
      hideModal() {
        this.showAddIssuesModal = false;
      },
    },
    template: `
      <footer class="form-actions add-issues-footer">
        <button
          class="btn btn-success pull-left"
          type="button">
          Add issues
        </button>
        <button
          class="btn btn-default pull-right"
          type="button"
          @click="hideModal">
          Cancel
        </button>
      </footer>
    `,
  });
})();
