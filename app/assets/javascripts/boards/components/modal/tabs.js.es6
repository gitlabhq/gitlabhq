/* global Vue */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalTabs = Vue.extend({
    data() {
      return ModalStore.globalStore;
    },
    methods: {
      changeTab(tab) {
        this.activeTab = tab;
      },
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
      <div class="top-area">
        <ul class="nav-links issues-state-filters">
          <li :class="{ 'active': activeTab == 'all' }">
            <a
              href="#"
              role="button"
              @click.prevent="changeTab('all')">
              <span>All issues</span>
              <span class="badge">
                {{ issues.length }}
              </span>
            </a>
          </li>
          <li :class="{ 'active': activeTab == 'selected' }">
            <a
              href="#"
              role="button"
              @click.prevent="changeTab('selected')">
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
