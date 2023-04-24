<script>
import { GlCollapse, GlCollapseToggleDirective, GlIcon } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import ItemsList from './items_list.vue';

export default {
  components: {
    GlCollapse,
    GlIcon,
    ItemsList,
  },
  directives: {
    CollapseToggle: GlCollapseToggleDirective,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    noResultsText: {
      type: String,
      required: true,
    },
    searchResults: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      expanded: true,
    };
  },
  computed: {
    isEmpty() {
      return !this.searchResults.length;
    },
    collapseIcon() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
  },
  created() {
    this.collapseId = uniqueId('expandable-section-');
  },
  buttonClasses: [
    // Reset user agent styles
    'gl-appearance-none',
    'gl-border-0',
    'gl-bg-transparent',
    // Text styles
    'gl-text-left',
    'gl-text-transform-uppercase',
    'gl-text-secondary',
    'gl-font-weight-bold',
    'gl-font-xs',
    'gl-line-height-12',
    'gl-letter-spacing-06em',
    // Border
    'gl-border-t',
    'gl-border-gray-50',
    // Spacing
    'gl-my-3',
    'gl-pt-2',
    'gl-w-full',
    // Layout
    'gl-display-flex',
    'gl-justify-content-space-between',
    'gl-align-items-center',
  ],
};
</script>

<template>
  <li class="gl-border-t gl-border-gray-50 gl-mx-3">
    <button
      v-collapse-toggle="collapseId"
      :class="$options.buttonClasses"
      data-testid="search-results-toggle"
    >
      {{ title }}
      <gl-icon :name="collapseIcon" :size="16" />
    </button>
    <gl-collapse :id="collapseId" v-model="expanded">
      <div v-if="isEmpty" data-testid="empty-text" class="gl-text-gray-500 gl-font-sm gl-mb-3">
        {{ noResultsText }}
      </div>
      <items-list :aria-label="title" :items="searchResults">
        <template #view-all-items>
          <slot name="view-all-items"></slot>
        </template>
      </items-list>
    </gl-collapse>
  </li>
</template>
