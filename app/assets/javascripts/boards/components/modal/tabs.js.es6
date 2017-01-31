/* global Vue */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.ModalTabs = Vue.extend({
    data() {
      return ModalStore.store;
    },
    computed: {
      selectedCount() {
        return ModalStore.selectedCount();
      },
    },
    destroyed() {
      this.activeTab = 'all';
    },
    template: `
      <div class="top-area prepend-top-10 append-bottom-10">
        <ul class="nav-links issues-state-filters">
          <li :class="{ 'active': activeTab == 'all' }">
            <a
              href="#"
              role="button"
              @click.prevent="activeTab = 'all'">
              <span>All issues</span>
              <span class="badge">
                {{ issuesCount }}
              </span>
            </a>
          </li>
          <li :class="{ 'active': activeTab == 'selected' }">
            <a
              href="#"
              role="button"
              @click.prevent="activeTab = 'selected'">
              <span>Selected issues</span>
              <span class="badge">
                {{ selectedCount }}
              </span>
            </a>
          </li>
        </ul>
      </div>
    `,
  });
})();
