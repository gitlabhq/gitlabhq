<script>
import { sanitizeItem } from '../utils';
import FrequentItemsListItem from './frequent_items_list_item.vue';
import frequentItemsMixin from './frequent_items_mixin';

export default {
  components: {
    FrequentItemsListItem,
  },
  mixins: [frequentItemsMixin],
  props: {
    items: {
      type: Array,
      required: true,
    },
    hasSearchQuery: {
      type: Boolean,
      required: true,
    },
    isFetchFailed: {
      type: Boolean,
      required: true,
    },
    isItemRemovalFailed: {
      type: Boolean,
      required: true,
    },
    matcher: {
      type: String,
      required: true,
    },
  },
  computed: {
    translations() {
      return this.getTranslations([
        'itemListEmptyMessage',
        'itemListErrorMessage',
        'searchListEmptyMessage',
        'searchListErrorMessage',
      ]);
    },
    isListEmpty() {
      return this.items.length === 0;
    },
    showListEmptyMessage() {
      return this.isListEmpty || this.isItemRemovalFailed;
    },
    listEmptyMessage() {
      if (this.hasSearchQuery) {
        return this.isFetchFailed
          ? this.translations.searchListErrorMessage
          : this.translations.searchListEmptyMessage;
      }

      return this.isFetchFailed || this.isItemRemovalFailed
        ? this.translations.itemListErrorMessage
        : this.translations.itemListEmptyMessage;
    },
    sanitizedItems() {
      return this.items.map(sanitizeItem);
    },
  },
};
</script>

<template>
  <div class="frequent-items-list-container">
    <ul data-testid="frequent-items-list" class="list-unstyled">
      <li
        v-if="showListEmptyMessage"
        :class="{ 'section-failure': isFetchFailed }"
        class="section-empty gl-mb-3"
        data-testid="frequent-items-list-empty"
      >
        {{ listEmptyMessage }}
      </li>
      <frequent-items-list-item
        v-for="item in sanitizedItems"
        v-else
        :key="item.id"
        :item-id="item.id"
        :item-name="item.name"
        :namespace="item.namespace"
        :web-url="item.webUrl"
        :avatar-url="item.avatarUrl"
        :matcher="matcher"
      />
    </ul>
  </div>
</template>
