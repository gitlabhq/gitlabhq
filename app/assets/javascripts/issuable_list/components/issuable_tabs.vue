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
  },
};
</script>

<template>
  <div class="top-area">
    <gl-tabs class="nav-links mobile-separator issuable-state-filters">
      <gl-tab
        v-for="tab in tabs"
        :key="tab.id"
        :active="isTabActive(tab.name)"
        @click="$emit('click', tab.name)"
      >
        <template #title>
          <span :title="tab.titleTooltip">{{ tab.title }}</span>
          <gl-badge v-if="tabCounts" variant="neutral" size="sm" class="gl-px-2 gl-py-1!">{{
            tabCounts[tab.name]
          }}</gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
    <div class="nav-controls">
      <slot name="nav-actions"></slot>
    </div>
  </div>
</template>
