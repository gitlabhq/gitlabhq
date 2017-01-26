//= require ./lists_dropdown
/* global Vue */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalFooter = Vue.extend({
    data() {
      return ModalStore.store;
    },
    computed: {
      submitDisabled() {
        return !ModalStore.selectedCount();
      },
      submitText() {
        const count = ModalStore.selectedCount();

        return `Add ${count} issue${count > 1 || !count ? 's' : ''}`;
      },
    },
    methods: {
      hideModal() {
        this.showAddIssuesModal = false;
      },
      addIssues() {
        const list = this.selectedList;
        const issueIds = this.selectedIssues.map(issue => issue.id);

        // Post the data to the backend
        gl.boardService.addMultipleIssues(list, issueIds);

        // Add the issues on the frontend
        this.selectedIssues.forEach((issue) => {
          list.addIssue(issue);
          list.issuesSize += 1;
        });

        this.hideModal();
      },
    },
    components: {
      'lists-dropdown': gl.issueBoards.ModalFooterListsDropdown,
    },
    template: `
      <footer class="form-actions add-issues-footer">
        <div class="pull-left">
          <button
            class="btn btn-success"
            type="button"
            :disabled="submitDisabled"
            @click="addIssues">
            {{ submitText }}
          </button>
          <span class="inline add-issues-footer-to-list">
            to list
          </span>
          <lists-dropdown></lists-dropdown>
        </div>
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
