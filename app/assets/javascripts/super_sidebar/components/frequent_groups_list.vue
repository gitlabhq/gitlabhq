<script>
import { s__ } from '~/locale';
import { MAX_FREQUENT_GROUPS_COUNT } from '../constants';
import FrequentItemsList from './frequent_items_list.vue';
import NavItem from './nav_item.vue';

export default {
  MAX_FREQUENT_GROUPS_COUNT,
  components: {
    FrequentItemsList,
    NavItem,
  },
  props: {
    username: {
      type: String,
      required: true,
    },
    viewAllLink: {
      type: String,
      required: true,
    },
    isSearch: {
      type: Boolean,
      required: false,
      default: false,
    },
    searchResults: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    storageKey() {
      return `${this.username}/frequent-groups`;
    },
    viewAllItem() {
      return {
        link: this.viewAllLink,
        title: s__('Navigation|View all groups'),
        icon: 'group',
      };
    },
  },
  i18n: {
    title: s__('Navigation|Frequent groups'),
    searchTitle: s__('Navigation|Groups'),
    pristineText: s__('Navigation|Groups you visit often will appear here.'),
    noResultsText: s__('Navigation|No group matches found'),
  },
};
</script>

<template>
  <frequent-items-list
    :title="$options.i18n.title"
    :search-title="$options.i18n.searchTitle"
    :storage-key="storageKey"
    :max-items="$options.MAX_FREQUENT_GROUPS_COUNT"
    :pristine-text="$options.i18n.pristineText"
    :no-results-text="$options.i18n.noResultsText"
    :is-search="isSearch"
    :search-results="searchResults"
  >
    <template #view-all-items>
      <nav-item :item="viewAllItem" />
    </template>
  </frequent-items-list>
</template>
