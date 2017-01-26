/* global Vue */
//= require ./header
//= require ./list
//= require ./footer
//= require ./empty_state
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.IssuesModal = Vue.extend({
    props: [
      'blankStateImage', 'newIssuePath',
    ],
    data() {
      return ModalStore.store;
    },
    watch: {
      searchTerm() {
        this.searchOperation();
      },
      showAddIssuesModal() {
        if (this.showAddIssuesModal && !this.issues.length) {
          this.loading = true;

          this.loadIssues()
            .then(() => {
              this.loading = false;
            });
        } else if (!this.showAddIssuesModal) {
          this.issues = [];
          this.selectedIssues = [];
        }
      },
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
    computed: {
      showList() {
        if (this.activeTab === 'selected') {
          return this.selectedIssues.length > 0;
        }

        return this.issues.length > 0;
      },
    },
    components: {
      'modal-header': gl.issueBoards.IssuesModalHeader,
      'modal-list': gl.issueBoards.ModalList,
      'modal-footer': gl.issueBoards.ModalFooter,
      'empty-state': gl.issueBoards.ModalEmptyState,
    },
    template: `
      <div
        class="add-issues-modal"
        v-if="showAddIssuesModal">
        <div class="add-issues-container">
          <modal-header></modal-header>
          <modal-list v-if="!loading && showList"></modal-list>
          <empty-state
            v-if="(!loading && issues.length === 0) || (activeTab === 'selected' && selectedIssues.length === 0)"
            :image="blankStateImage"
            :new-issue-path="newIssuePath"></empty-state>
          <section
            class="add-issues-list text-center"
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
