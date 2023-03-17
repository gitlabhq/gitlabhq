<script>
import ItemsList from './items_list.vue';

export default {
  components: {
    ItemsList,
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
  computed: {
    isEmpty() {
      return !this.searchResults.length;
    },
  },
};
</script>

<template>
  <li class="gl-border-t gl-border-gray-50 gl-mx-3 gl-py-3">
    <div
      data-testid="list-title"
      aria-hidden="true"
      class="gl-text-transform-uppercase gl-text-secondary gl-font-weight-bold gl-font-xs gl-line-height-12 gl-letter-spacing-06em gl-my-3"
    >
      {{ title }}
    </div>
    <div v-if="isEmpty" data-testid="empty-text" class="gl-text-gray-500 gl-font-sm gl-my-3">
      {{ noResultsText }}
    </div>
    <items-list :aria-label="title" :items="searchResults">
      <template #view-all-items>
        <slot name="view-all-items"></slot>
      </template>
    </items-list>
  </li>
</template>
