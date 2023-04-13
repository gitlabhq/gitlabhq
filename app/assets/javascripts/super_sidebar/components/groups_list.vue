<script>
import { s__ } from '~/locale';
import { MAX_FREQUENT_GROUPS_COUNT } from '../constants';
import FrequentItemsList from './frequent_items_list.vue';
import SearchResults from './search_results.vue';
import NavItem from './nav_item.vue';

export default {
  MAX_FREQUENT_GROUPS_COUNT,
  components: {
    FrequentItemsList,
    SearchResults,
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
    viewAllProps() {
      return {
        item: {
          link: this.viewAllLink,
          title: s__('Navigation|View all your groups'),
          icon: 'group',
        },
        linkClasses: { 'dashboard-shortcuts-groups': true },
      };
    },
  },
  i18n: {
    title: s__('Navigation|Frequently visited groups'),
    searchTitle: s__('Navigation|Groups'),
    pristineText: s__('Navigation|Groups you visit often will appear here.'),
    noResultsText: s__('Navigation|No group matches found'),
  },
};
</script>

<template>
  <search-results
    v-if="isSearch"
    :title="$options.i18n.searchTitle"
    :no-results-text="$options.i18n.noResultsText"
    :search-results="searchResults"
  >
    <template #view-all-items>
      <nav-item v-bind="viewAllProps" />
    </template>
  </search-results>
  <frequent-items-list
    v-else
    :title="$options.i18n.title"
    :storage-key="storageKey"
    :max-items="$options.MAX_FREQUENT_GROUPS_COUNT"
    :pristine-text="$options.i18n.pristineText"
  >
    <template #view-all-items>
      <nav-item v-bind="viewAllProps" />
    </template>
  </frequent-items-list>
</template>
