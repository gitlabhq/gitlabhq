<script>
import { GlSorting } from '@gitlab/ui';
import { __ } from '~/locale';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  RECENT_SEARCHES_STORAGE_KEY_GROUPS,
  RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
} from '~/filtered_search/recent_searches_storage_keys';
import {
  filterToQueryObject,
  processFilters,
  urlQueryToFilter,
  prepareTokens,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_EMPTY_SEARCH_TERM,
} from '~/vue_shared/components/filtered_search_bar/constants';

export default {
  i18n: {
    searchInputPlaceholder: __('Search or filter results…'),
  },
  components: {
    FilteredSearchBar,
    GlSorting,
  },
  props: {
    filteredSearchTokens: {
      type: Array,
      required: true,
    },
    /**
     * Filtered search value as an object. Can come from `$route.query` if using Vue router
     * or manually convert the query string to an object using `queryToObject` util.
     *
     * Example:
     *
     * {
     *   search: 'foo bar',
     *   role: 'Owner'
     * }
     */
    filteredSearchQuery: {
      type: Object,
      required: true,
    },
    filteredSearchTermKey: {
      type: String,
      required: true,
    },
    filteredSearchNamespace: {
      type: String,
      required: true,
    },
    filteredSearchRecentSearchesStorageKey: {
      type: String,
      required: true,
      validator(value) {
        return [RECENT_SEARCHES_STORAGE_KEY_GROUPS, RECENT_SEARCHES_STORAGE_KEY_PROJECTS].includes(
          value,
        );
      },
    },
    sortOptions: {
      type: Array,
      required: true,
    },
    activeSortOption: {
      type: Object,
      required: true,
    },
    isAscending: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    filteredSearchValue() {
      const tokens = prepareTokens(
        urlQueryToFilter(this.filteredSearchQuery, {
          filteredSearchTermKey: this.filteredSearchTermKey,
          filterNamesAllowList: [FILTERED_SEARCH_TERM],
        }),
      );

      return tokens.length ? tokens : [TOKEN_EMPTY_SEARCH_TERM];
    },
  },
  methods: {
    onFilter(filters) {
      this.$emit(
        'filter',
        filterToQueryObject(processFilters(filters), {
          filteredSearchTermKey: this.filteredSearchTermKey,
        }),
      );
    },
  },
};
</script>

<template>
  <div class="gl-p-5 gl-bg-gray-10 gl-border-t gl-border-b">
    <div class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-gap-3">
      <div class="gl-flex-grow-1">
        <filtered-search-bar
          :namespace="filteredSearchNamespace"
          :tokens="filteredSearchTokens"
          :initial-filter-value="filteredSearchValue"
          sync-filter-and-sort
          :recent-searches-storage-key="filteredSearchRecentSearchesStorageKey"
          :search-input-placeholder="$options.i18n.searchInputPlaceholder"
          @onFilter="onFilter"
        />
      </div>
      <div v-if="$scopedSlots.default">
        <slot></slot>
      </div>
      <div>
        <gl-sorting
          class="gl-display-flex"
          dropdown-class="gl-w-full"
          block
          :text="activeSortOption.text"
          :is-ascending="isAscending"
          :sort-options="sortOptions"
          :sort-by="activeSortOption.value"
          @sortDirectionChange="$emit('sort-direction-change', $event)"
          @sortByChange="$emit('sort-by-change', $event)"
        />
      </div>
    </div>
  </div>
</template>
