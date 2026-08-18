<script>
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

export default {
  name: 'SearchAndSortBar',
  components: {
    FilteredSearchBar,
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
  emits: ['on-filter', 'on-sort'],
  methods: {
    onFilter(searchTerms) {
      const searchQuery = searchTerms.reduce((terms, searchTerm) => {
        if (searchTerm.type !== FILTERED_SEARCH_TERM) {
          return '';
        }

        return `${terms} ${searchTerm.value.data}`;
      }, '');

      this.$emit('on-filter', searchQuery.trim() || null);
    },
    onSort(value) {
      this.$emit('on-sort', value);
    },
  },
};
</script>

<template>
  <filtered-search-bar
    :namespace="namespace"
    :tokens="[] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */"
    :search-input-placeholder="searchInputPlaceholder"
    :sort-options="sortOptions"
    :initial-sort-by="initialSortBy"
    class="gl-grow"
    @on-filter="onFilter"
    @on-sort="onSort"
  />
</template>
