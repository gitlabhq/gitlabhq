//= require ./lists_dropdown
/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalFooter = Vue.extend({
    data() {
      return {
        store: Store.modal,
        disabled: false,
      };
    },
    computed: {
      submitDisabled() {
        if (this.disabled) return true;

        return !Store.modalSelectedCount();
      },
      submitText() {
        const count = Store.modalSelectedCount();

        return `Add ${count} issue${count > 1 || !count ? 's' : ''}`;
      },
    },
    methods: {
      hideModal() {
        this.store.showAddIssuesModal = false;
      },
      addIssues() {
        const issueIds = this.store.issues.filter(issue => issue.selected).map(issue => issue.id);

        issueIds.forEach((id) => {
          const issue = this.store.issues.filter(issue => issue.id == id)[0];
          this.store.selectedList.addIssue(issue);
          this.store.selectedList.issuesSize += 1;
        });

        this.disabled = true;
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
          <span class="add-issues-footer-to-list">
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
