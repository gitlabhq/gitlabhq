/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.DismissModal = Vue.extend({
    data() {
      return Store.modal;
    },
    methods: {
      toggleModal(toggle) {
        this.showAddIssuesModal = toggle;
      },
    },
    template: `
      <button
        type="button"
        class="close"
        data-dismiss="modal"
        aria-label="Close"
        @click="toggleModal(false)">
        <span aria-hidden="true">×</span>
      </button>
    `,
  });
})();
