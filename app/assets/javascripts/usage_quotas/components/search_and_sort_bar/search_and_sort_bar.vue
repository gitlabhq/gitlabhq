<script>
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSortContainerRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

export default {
  name: 'SearchAndSortBar',
  components: {
    FilteredSortContainerRoot,
  },
  props: {
    // Search
    namespace: {
      type: [Number, String],
      required: true,
    },
    searchInputPlaceholder: {
      type: String,
      required: true,
    },
    recentSearchesStorageKey: {
      type: String,
      required: false,
      default: '',
    },
    initialFilterValue: {
      type: Array,
      required: false,
      default: () => [],
    },
    // Sort
    initialSortBy: {
      type: String,
      required: false,
      default: '',
      validator: (value) => value === '' || /(_desc)|(_asc)/gi.test(value),
    },
    sortOptions: {
      type: Array,
      default: () => [],
      required: false,
    },
  },
  emits: ['onFilter', 'onSort'],
  methods: {
    onFilter(searchTerms) {
      const searchQuery = searchTerms.reduce((terms, searchTerm) => {
        if (searchTerm.type !== FILTERED_SEARCH_TERM) {
          return '';
        }

        return `${terms} ${searchTerm.value.data}`;
      }, '');

      this.$emit('onFilter', searchQuery.trim() || null);
    },
    onSort(value) {
      this.$emit('onSort', value);
    },
  },
};
</script>

<template>
  <filtered-sort-container-root
    :namespace="namespace"
    :tokens="[] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */"
    :search-input-placeholder="searchInputPlaceholder"
    :sort-options="sortOptions"
    :initial-sort-by="initialSortBy"
    class="gl-grow"
    @onFilter="onFilter"
    @onSort="onSort"
  />
</template>
