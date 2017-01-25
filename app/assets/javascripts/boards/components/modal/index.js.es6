/* global Vue */
//= require ./header
//= require ./list
//= require ./footer
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.IssuesModal = Vue.extend({
    data() {
      return ModalStore.store;
    },
    watch: {
      searchTerm() {
        this.searchOperation();
      },
    },
    mounted() {
      this.loading = true;

      this.loadIssues()
        .then(() => {
          this.loading = false;
        });
    },
    methods: {
      searchOperation: _.debounce(function() {
        this.loadIssues();
      }, 500),
      loadIssues() {
        return gl.boardService.getBacklog({
          search: this.searchTerm,
        }).then((res) => {
          const data = res.json();

          this.issues = [];
          data.forEach((issueObj) => {
            const issue = new ListIssue(issueObj);
            const foundSelectedIssue = ModalStore.findSelectedIssue(issue);
            issue.selected = foundSelectedIssue !== undefined;

            this.issues.push(issue);
          });
        });
      },
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
          <modal-list v-if="!loading"></modal-list>
          <section
            class="add-issues-list"
            v-if="loading">
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
