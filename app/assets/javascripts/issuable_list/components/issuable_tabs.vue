<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlTabs,
    GlTab,
    GlBadge,
  },
  props: {
    tabs: {
      type: Array,
      required: true,
    },
    tabCounts: {
      type: Object,
      required: false,
      default: null,
    },
    currentTab: {
      type: String,
      required: true,
    },
  },
  methods: {
    isTabActive(tabName) {
      return tabName === this.currentTab;
    },
    isTabCountNumeric(tab) {
      return Number.isInteger(this.tabCounts[tab.name]);
    },
  },
};
</script>

<template>
  <div class="top-area">
    <gl-tabs
      class="gl-display-flex gl-flex-grow-1 gl-p-0 gl-m-0 mobile-separator issuable-state-filters"
      nav-class="gl-border-b-0"
    >
      <gl-tab
        v-for="tab in tabs"
        :key="tab.id"
        :active="isTabActive(tab.name)"
        @click="$emit('click', tab.name)"
      >
        <template #title>
          <span :title="tab.titleTooltip">{{ tab.title }}</span>
          <gl-badge
            v-if="tabCounts && isTabCountNumeric(tab)"
            variant="neutral"
            size="sm"
            class="gl-tab-counter-badge"
          >
            {{ tabCounts[tab.name] }}
          </gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
    <div class="nav-controls">
      <slot name="nav-actions"></slot>
    </div>
  </div>
</template>
