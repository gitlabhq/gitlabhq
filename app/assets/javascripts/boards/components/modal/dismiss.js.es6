/* global Vue */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.DismissModal = Vue.extend({
    data() {
      return ModalStore.store;
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
