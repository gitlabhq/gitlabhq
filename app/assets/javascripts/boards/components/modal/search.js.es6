/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalSearch = Vue.extend({
    data() {
      return Store.modal;
    },
    computed: {
      selectAllText() {
        if (Store.modalSelectedCount() !== this.issues.length || this.issues.length === 0) {
          return 'Select all';
        }

        return 'Un-select all';
      },
    },
    methods: {
      toggleAll() {
        const select = Store.modalSelectedCount() !== this.issues.length;

        this.issues.forEach((issue) => {
          const issueUpdate = issue;

          if (issueUpdate.selected !== select) {
            issueUpdate.selected = select;

            if (select) {
              this.selectedIssues.push(issueUpdate);
            } else {
              const index = this.selectedIssues.indexOf(issue);
              this.selectedIssues.splice(index, 1);
            }
          }
        });
      },
    },
    template: `
      <div
        class="add-issues-search"
        v-if="activeTab == 'all'">
        <input
          placeholder="Search issues..."
          class="form-control"
          type="search"
          v-model="searchTerm" />
        <button
          type="button"
          class="btn btn-success btn-inverted"
          @click="toggleAll">
          {{ selectAllText }}
        </button>
      </div>
    `,
  });
})();
