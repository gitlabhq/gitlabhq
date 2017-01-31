//= require ./lists_dropdown
/* global Vue */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

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

        return `Add ${count > 0 ? count : ''} issue${count > 1 || !count ? 's' : ''}`;
      },
    },
    methods: {
      hideModal() {
        this.showAddIssuesModal = false;
      },
      addIssues() {
        const list = this.selectedList;
        const selectedIssues = ModalStore.getSelectedIssues();
        const issueIds = selectedIssues.map(issue => issue.globalId);

        // Post the data to the backend
        gl.boardService.bulkUpdate(issueIds, {
          add_label_ids: [list.label.id],
        });

        // Add the issues on the frontend
        selectedIssues.forEach((issue) => {
          list.addIssue(issue);
          list.issuesSize += 1;
        });

        this.hideModal();
      },
    },
    components: {
      listsDropdown: gl.issueBoards.ModalFooterListsDropdown,
    },
    template: `
      <footer
        class="form-actions add-issues-footer">
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
