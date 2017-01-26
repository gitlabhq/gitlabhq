/* global Vue */
//= require ./tabs
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.IssuesModalHeader = Vue.extend({
    data() {
      return ModalStore.store;
    },
    computed: {
      selectAllText() {
        if (ModalStore.selectedCount() !== this.issues.length || this.issues.length === 0) {
          return 'Select all';
        }

        return 'Un-select all';
      },
    },
    methods: {
      toggleAll: ModalStore.toggleAll.bind(ModalStore),
    },
    components: {
      'modal-tabs': gl.issueBoards.ModalTabs,
    },
    template: `
      <div>
        <header class="add-issues-header form-actions">
          <h2>
            Add issues
            <button
              type="button"
              class="close"
              data-dismiss="modal"
              aria-label="Close"
              @click="showAddIssuesModal = false">
              <span aria-hidden="true">×</span>
            </button>
          </h2>
        </header>
        <modal-tabs v-if="!loading"></modal-tabs>
        <div
          class="add-issues-search prepend-top-10 append-bottom-10"
          v-if="activeTab == 'all' && !loading">
          <input
            placeholder="Search issues..."
            class="form-control"
            type="search"
            v-model="searchTerm" />
          <button
            type="button"
            class="btn btn-success btn-inverted prepend-left-10"
            @click="toggleAll">
            {{ selectAllText }}
          </button>
        </div>
      </div>
    `,
  });
})();
