<script>
import { mapActions, mapState } from 'vuex';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import IdeSidebarNav from '../ide_sidebar_nav.vue';

export default {
  name: 'CollapsibleSidebar',
  directives: {
    tooltip,
  },
  components: {
    Icon,
    IdeSidebarNav,
  },
  props: {
    extensionTabs: {
      type: Array,
      required: false,
      default: () => [],
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
      return this.extensionTabs.filter(tab => tab.show);
    },
    tabViews() {
      return this.tabs.map(tab => tab.views).flat();
    },
    aliveTabViews() {
      return this.tabViews.filter(view => this.isAliveView(view.name));
    },
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
  },
};
</script>

<template>
  <div
    :class="`ide-${side}-sidebar`"
    :data-qa-selector="`ide_${side}_sidebar`"
    class="multi-file-commit-panel ide-sidebar"
  >
    <div
      v-show="isOpen"
      :class="`ide-${side}-sidebar-${currentView}`"
      class="multi-file-commit-panel-inner"
    >
      <div
        v-for="tabView in aliveTabViews"
        v-show="tabView.name === currentView"
        :key="tabView.name"
        class="flex-fill gl-overflow-hidden js-tab-view gl-h-full"
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
