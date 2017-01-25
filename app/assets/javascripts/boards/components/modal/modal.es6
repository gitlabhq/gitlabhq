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
    mounted() {
      gl.boardService.getBacklog()
        .then((res) => {
          const data = res.json();

          data.forEach((issueObj) => {
            this.issues.push(new ListIssue(issueObj));
          });
        });
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
          <modal-list v-if="issues.length"></modal-list>
          <section
            class="add-issues-list"
            v-if="issues.length == 0">
            <div class="add-issues-list-loading">
              <i class="fa fa-spinner fa-spin"></i>
            </div>
          </section>
          <modal-footer></modal-footer>
        </div>
      </div>
    `,
  });
})();
