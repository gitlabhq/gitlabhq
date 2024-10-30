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
      required: false,
      default() {
        return [];
      },
    },
    activeSortOption: {
      type: Object,
      required: true,
    },
    isAscending: {
      type: Boolean,
      required: true,
    },
    searchInputPlaceholder: {
      type: String,
      required: false,
      default: __('Search or filter results…'),
    },
  },
  computed: {
    filteredSearchValue() {
      const tokens = prepareTokens(
        urlQueryToFilter(this.filteredSearchQuery, {
          filteredSearchTermKey: this.filteredSearchTermKey,
          filterNamesAllowList: [
            FILTERED_SEARCH_TERM,
            ...this.filteredSearchTokens.map(({ type }) => type),
          ],
        }),
      );

      return tokens.length ? tokens : [TOKEN_EMPTY_SEARCH_TERM];
    },
    shouldShowSort() {
      return this.sortOptions.length;
    },
  },
  methods: {
    onFilter(filters) {
      this.$emit(
        'filter',
        filterToQueryObject(processFilters(filters), {
          filteredSearchTermKey: this.filteredSearchTermKey,
          shouldExcludeEmpty: true,
        }),
      );
    },
  },
};
</script>

<template>
  <div class="gl-border-t gl-bg-subtle gl-p-5">
    <div class="gl-flex gl-flex-col gl-gap-3 md:gl-flex-row">
      <div class="gl-grow">
        <filtered-search-bar
          :namespace="filteredSearchNamespace"
          :tokens="filteredSearchTokens"
          :initial-filter-value="filteredSearchValue"
          sync-filter-and-sort
          :recent-searches-storage-key="filteredSearchRecentSearchesStorageKey"
          :search-input-placeholder="searchInputPlaceholder"
          terms-as-tokens
          @onFilter="onFilter"
        />
      </div>
      <div v-if="$scopedSlots.default">
        <slot></slot>
      </div>
      <div v-if="shouldShowSort" data-testid="groups-projects-sort">
        <gl-sorting
          class="gl-flex"
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
