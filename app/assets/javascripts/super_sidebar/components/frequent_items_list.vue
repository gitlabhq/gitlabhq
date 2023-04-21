<script>
import * as Sentry from '@sentry/browser';
import AccessorUtilities from '~/lib/utils/accessor';
import { getTopFrequentItems, formatContextSwitcherItems } from '../utils';
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
    pristineText: {
      type: String,
      required: true,
    },
    storageKey: {
      type: String,
      required: true,
    },
    maxItems: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      cachedFrequentItems: [],
    };
  },
  computed: {
    isEmpty() {
      return !this.cachedFrequentItems.length;
    },
  },
  created() {
    this.getItemsFromLocalStorage();
  },
  methods: {
    getItemsFromLocalStorage() {
      if (!AccessorUtilities.canUseLocalStorage()) {
        return;
      }
      try {
        const parsedCachedFrequentItems = JSON.parse(localStorage.getItem(this.storageKey));
        const topFrequentItems = getTopFrequentItems(parsedCachedFrequentItems, this.maxItems);
        this.cachedFrequentItems = formatContextSwitcherItems(topFrequentItems);
      } catch (e) {
        Sentry.captureException(e);
      }
    },
    handleItemRemove(item) {
      try {
        // Remove item from local storage
        const parsedCachedFrequentItems = JSON.parse(localStorage.getItem(this.storageKey));
        localStorage.setItem(
          this.storageKey,
          JSON.stringify(parsedCachedFrequentItems.filter((i) => i.id !== item.id)),
        );

        // Update the list
        this.cachedFrequentItems = this.cachedFrequentItems.filter((i) => i.id !== item.id);
      } catch (e) {
        Sentry.captureException(e);
      }
    },
  },
};
</script>

<template>
  <li class="gl-border-t gl-border-gray-50 gl-mx-3 gl-py-3">
    <div
      data-testid="list-title"
      aria-hidden="true"
      class="gl-display-flex gl-align-items-center gl-text-transform-uppercase gl-text-secondary gl-font-weight-bold gl-font-xs gl-line-height-12 gl-letter-spacing-06em gl-my-3"
    >
      <span class="gl-flex-grow-1">{{ title }}</span>
    </div>
    <div v-if="isEmpty" data-testid="empty-text" class="gl-text-gray-500 gl-font-sm gl-my-3">
      {{ pristineText }}
    </div>
    <items-list :aria-label="title" :items="cachedFrequentItems" @remove-item="handleItemRemove">
      <template #view-all-items>
        <slot name="view-all-items"></slot>
      </template>
    </items-list>
  </li>
</template>
