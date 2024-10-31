<script>
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import {
  FILTERED_SEARCH_NAMESPACE,
  FILTERED_SEARCH_TERM_KEY,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_OPTION_CREATED_DATE,
  SORT_OPTIONS,
} from '~/admin/groups/constants';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import { objectToQuery, queryToObject, visitUrl } from '~/lib/utils/url_utility';

export default {
  components: {
    FilteredSearchAndSort,
  },
  computed: {
    defaultSortOption() {
      return SORT_OPTION_CREATED_DATE;
    },
    defaultSortBy() {
      return `${this.defaultSortOption.value}_${SORT_DIRECTION_DESC}`;
    },
    queryAsObject() {
      return queryToObject(document.location.search);
    },
    queryAsObjectWithoutPagination() {
      const { page, ...queryAsObject } = this.queryAsObject;
      return queryAsObject;
    },
    sortByQuery() {
      return this.queryAsObject.sort;
    },
    sortBy() {
      return this.sortByQuery || this.defaultSortBy;
    },
    sortOptions() {
      return SORT_OPTIONS;
    },
    activeSortOption() {
      return (
        this.sortOptions.find((option) => this.sortBy.includes(option.value)) ||
        this.defaultSortOption
      );
    },
    isAscending() {
      return this.sortBy.endsWith(SORT_DIRECTION_ASC);
    },
  },
  methods: {
    visitUrlWithQueryObject(queryObject) {
      return visitUrl(`?${objectToQuery(queryObject)}`);
    },
    onSortChange(sortBy, isAscending) {
      const sort = `${sortBy}_${isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC}`;
      this.visitUrlWithQueryObject({ ...this.queryAsObjectWithoutPagination, sort });
    },
    onSortDirectionChange(isAscending) {
      this.onSortChange(this.activeSortOption.value, isAscending);
    },
    onSortByChange(sortBy) {
      this.onSortChange(sortBy, this.isAscending);
    },
    onFilter(filtersQuery) {
      const queryObject = { ...filtersQuery };

      if (this.sortByQuery) {
        queryObject.sort = this.sortByQuery;
      }

      this.visitUrlWithQueryObject(queryObject);
    },
  },
  filteredSearch: {
    recentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
    namespace: FILTERED_SEARCH_NAMESPACE,
    termKey: FILTERED_SEARCH_TERM_KEY,
    tokens: [],
  },
};
</script>

<template>
  <div class="gl-mb-4" data-testid="admin-groups-filtered-search-and-sort">
    <filtered-search-and-sort
      :filtered-search-namespace="$options.filteredSearch.namespace"
      :filtered-search-tokens="$options.filteredSearch.tokens"
      :filtered-search-term-key="$options.filteredSearch.termKey"
      :filtered-search-recent-searches-storage-key="
        $options.filteredSearch.recentSearchesStorageKey
      "
      :is-ascending="isAscending"
      :sort-options="sortOptions"
      :active-sort-option="activeSortOption"
      :filtered-search-query="queryAsObject"
      @filter="onFilter"
      @sort-direction-change="onSortDirectionChange"
      @sort-by-change="onSortByChange"
    />
  </div>
</template>
