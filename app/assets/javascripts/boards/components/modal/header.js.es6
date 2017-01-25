//= require ./dismiss
//= require ./tabs
//= require ./search
/* global Vue */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.IssuesModalHeader = Vue.extend({
    data() {
      return ModalStore.globalStore;
    },
    components: {
      'modal-dismiss': gl.issueBoards.DismissModal,
      'modal-tabs': gl.issueBoards.ModalTabs,
      'modal-search': gl.issueBoards.ModalSearch,
    },
    template: `
      <div>
        <header class="add-issues-header form-actions">
          <h2>
            Add issues
            <modal-dismiss></modal-dismiss>
          </h2>
        </header>
        <modal-tabs v-if="!loading"></modal-tabs>
        <modal-search v-if="!loading"></modal-search>
      </div>
    `,
  });
})();
