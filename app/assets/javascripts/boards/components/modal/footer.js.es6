/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalFooter = Vue.extend({
    data() {
      return Object.assign({}, Store.modal, {
        disabled: false,
      });
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
        this.showAddIssuesModal = false;
      },
      addIssues() {
        const issueIds = this.issues.filter(issue => issue.selected).map(issue => issue.id);

        this.disabled = true;
      },
    },
    template: `
      <footer class="form-actions add-issues-footer">
        <button
          class="btn btn-success pull-left"
          type="button"
          :disabled="submitDisabled"
          @click="addIssues">
          {{ submitText }}
        </button>
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
