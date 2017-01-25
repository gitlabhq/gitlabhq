/* global Vue */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalSearch = Vue.extend({
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
