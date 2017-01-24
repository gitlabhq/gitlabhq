//= require ./dismiss
//= require ./tabs
//= require ./search
/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.IssuesModalHeader = Vue.extend({
    data() {
      return Store.modal;
    },
    components: {
      'modal-dismiss': gl.issueBoards.DismissModal,
      'modal-tabs': gl.issueBoards.ModalTabs,
      'modal-search': gl.issueBoards.ModalSearch,
    },
    template: `
      <header class="add-issues-header">
        <h2>
          Add issues to board
          <modal-dismiss></modal-dismiss>
        </h2>
        <modal-tabs></modal-tabs>
        <modal-search></modal-search>
      </header>
    `,
  });
})();
