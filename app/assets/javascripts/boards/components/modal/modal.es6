//= require ./header
//= require ./list
//= require ./footer
/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.IssuesModal = Vue.extend({
    data() {
      return Store.modal;
    },
    components: {
      'modal-header': gl.issueBoards.IssuesModalHeader,
      'modal-list': gl.issueBoards.ModalList,
      'modal-footer': gl.issueBoards.ModalFooter,
    },
    template: `
      <div
        class="add-issues-modal"
        v-if="showAddIssuesModal">
        <div class="add-issues-container">
          <modal-header></modal-header>
          <modal-list></modal-list>
          <modal-footer></modal-footer>
        </div>
      </div>
    `,
  });
})();
