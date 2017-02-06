/* eslint-disable no-new */
/* global Vue */
/* global Flash */

require('./lists_dropdown');

(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.ModalFooter = Vue.extend({
    mixins: [gl.issueBoards.ModalMixins],
    data() {
      return {
        modal: ModalStore.store,
        state: gl.issueBoards.BoardsStore.state,
      };
    },
    computed: {
      submitDisabled() {
        return !ModalStore.selectedCount();
      },
      submitText() {
        const count = ModalStore.selectedCount();

        return `Add ${count > 0 ? count : ''} ${gl.text.pluralize('issue', count)}`;
      },
    },
    methods: {
      addIssues() {
        const list = this.modal.selectedList || this.state.lists[0];
        const selectedIssues = ModalStore.getSelectedIssues();
        const issueIds = selectedIssues.map(issue => issue.globalId);

        // Post the data to the backend
        gl.boardService.bulkUpdate(issueIds, {
          add_label_ids: [list.label.id],
        }).catch(() => {
          new Flash('Failed to update issues, please try again.', 'alert');

          selectedIssues.forEach((issue) => {
            list.removeIssue(issue);
            list.issuesSize -= 1;
          });
        });

        // Add the issues on the frontend
        selectedIssues.forEach((issue) => {
          list.addIssue(issue);
          list.issuesSize += 1;
        });

        this.toggleModal(false);
      },
    },
    components: {
      'lists-dropdown': gl.issueBoards.ModalFooterListsDropdown,
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
          @click="toggleModal(false)">
          Cancel
        </button>
      </footer>
    `,
  });
})();
