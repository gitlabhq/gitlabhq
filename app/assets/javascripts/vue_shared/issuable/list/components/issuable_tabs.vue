<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { formatNumber } from '~/locale';

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
    truncateCounts: {
      type: Boolean,
      required: false,
      default: false,
    },
    addPadding: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    isTabActive(tabName) {
      return tabName === this.currentTab;
    },
    isTabCountNumeric(tab) {
      return Number.isInteger(this.tabCounts[tab.name]);
    },
    formatNumber(count) {
      return this.truncateCounts ? numberToMetricPrefix(count) : formatNumber(count);
    },
  },
};
</script>

<template>
  <div class="top-area">
    <gl-tabs
      class="mobile-separator issuable-state-filters gl-m-0 gl-flex gl-grow gl-p-0"
      nav-class="gl-border-b-0"
    >
      <gl-tab
        v-for="tab in tabs"
        :key="tab.id"
        :active="isTabActive(tab.name)"
        @click="$emit('click', tab.name)"
      >
        <template #title>
          <span :title="tab.titleTooltip" :data-testid="`${tab.name}-issuables-tab`">
            {{ tab.title }}
          </span>
          <gl-badge
            v-if="tabCounts && isTabCountNumeric(tab)"
            variant="muted"
            class="gl-tab-counter-badge"
          >
            {{ formatNumber(tabCounts[tab.name]) }}
          </gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
    <div :class="['nav-controls', { 'gl-py-3': addPadding }]">
      <slot name="nav-actions"></slot>
    </div>
  </div>
</template>
