<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import IdeSidebarNav from '../ide_sidebar_nav.vue';

export default {
  name: 'CollapsibleSidebar',
  components: {
    IdeSidebarNav,
  },
  props: {
    extensionTabs: {
      type: Array,
      required: false,
      default: () => [],
    },
    initOpenView: {
      type: String,
      required: false,
      default: '',
    },
    side: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState({
      isOpen(state) {
        return state[this.namespace].isOpen;
      },
      currentView(state) {
        return state[this.namespace].currentView;
      },
      isAliveView(_state, getters) {
        return getters[`${this.namespace}/isAliveView`];
      },
    }),
    namespace() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${this.side}Pane`;
    },
    tabs() {
      return this.extensionTabs.filter((tab) => tab.show);
    },
    tabViews() {
      return this.tabs.map((tab) => tab.views).flat();
    },
    aliveTabViews() {
      return this.tabViews.filter((view) => this.isAliveView(view.name));
    },
  },
  created() {
    this.openViewByName(this.initOpenView);
  },
  methods: {
    ...mapActions({
      toggleOpen(dispatch) {
        return dispatch(`${this.namespace}/toggleOpen`);
      },
      open(dispatch, view) {
        return dispatch(`${this.namespace}/open`, view);
      },
    }),
    openViewByName(viewName) {
      const view = viewName && this.tabViews.find((x) => x.name === viewName);

      if (view) {
        this.open(view);
      }
    },
  },
};
</script>

<template>
  <div :class="`ide-${side}-sidebar`" class="multi-file-commit-panel ide-sidebar">
    <div
      v-show="isOpen"
      :class="`ide-${side}-sidebar-${currentView}`"
      class="multi-file-commit-panel-inner"
    >
      <div
        v-for="tabView in aliveTabViews"
        v-show="tabView.name === currentView"
        :key="tabView.name"
        class="flex-fill js-tab-view gl-h-full gl-overflow-hidden"
      >
        <component :is="tabView.component" />
      </div>
    </div>
    <ide-sidebar-nav
      :tabs="tabs"
      :side="side"
      :current-view="currentView"
      :is-open="isOpen"
      @open="open"
      @close="toggleOpen"
    />
  </div>
</template>
