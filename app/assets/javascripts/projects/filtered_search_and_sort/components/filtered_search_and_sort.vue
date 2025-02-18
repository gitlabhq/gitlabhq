<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import { __ } from '~/locale';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import { queryToObject, objectToQuery, visitUrl } from '~/lib/utils/url_utility';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { ACCESS_LEVEL_OWNER_INTEGER } from '~/access_level/constants';
import { InternalEvents } from '~/tracking';
import {
  SORT_OPTIONS,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_OPTION_UPDATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '../constants';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'ProjectsFilteredSearchAndSort',
  filteredSearch: {
    namespace: FILTERED_SEARCH_NAMESPACE,
    recentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
    searchTermKey: FILTERED_SEARCH_TERM_KEY,
  },
  components: {
    FilteredSearchAndSort,
  },
  mixins: [trackingMixin],
  inject: [
    'initialSort',
    'programmingLanguages',
    'pathsToExcludeSortOn',
    'sortEventName',
    'filterEventName',
  ],
  computed: {
    filteredSearchTokens() {
      return [
        {
          type: 'language',
          icon: 'code',
          title: __('Language'),
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: this.programmingLanguages.map(({ id, name }) => ({
            // Cast to string so it matches value from query string
            value: id.toString(),
            title: name,
          })),
        },
        {
          type: 'min_access_level',
          icon: 'user',
          title: __('Role'),
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            {
              // Cast to string so it matches value from query string
              value: ACCESS_LEVEL_OWNER_INTEGER.toString(),
              title: __('Owner'),
            },
          ],
        },
      ];
    },
    queryAsObject() {
      return queryToObject(document.location.search);
    },
    queryAsObjectWithoutPagination() {
      const { page, ...queryAsObject } = this.queryAsObject;

      return queryAsObject;
    },
    sortByQuery() {
      return this.queryAsObject?.sort;
    },
    sortBy() {
      if (this.sortByQuery) {
        return this.sortByQuery;
      }

      return this.initialSort;
    },
    search() {
      return this.queryAsObject?.[FILTERED_SEARCH_TERM_KEY] || '';
    },
    sortOptions() {
      if (this.pathsToExcludeSortOn.includes(window.location.pathname)) {
        return [];
      }

      return SORT_OPTIONS;
    },
    activeSortOption() {
      return (
        SORT_OPTIONS.find((sortItem) => this.sortBy.includes(sortItem.value)) || SORT_OPTION_UPDATED
      );
    },
    isAscending() {
      if (!this.sortBy) {
        return true;
      }

      return this.sortBy.endsWith(SORT_DIRECTION_ASC);
    },
  },
  methods: {
    visitUrlWithQueryObject(queryObject) {
      return visitUrl(`?${objectToQuery(queryObject)}`);
    },
    onSortDirectionChange(isAscending) {
      const sort = `${this.activeSortOption.value}_${
        isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC
      }`;

      this.trackEvent(this.sortEventName, {
        label: sort,
      });

      this.visitUrlWithQueryObject({
        ...this.queryAsObjectWithoutPagination,
        sort,
      });
    },
    onSortByChange(sortBy) {
      const sort = `${sortBy}_${this.isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC}`;

      this.trackEvent(this.sortEventName, {
        label: sort,
      });

      this.visitUrlWithQueryObject({ ...this.queryAsObjectWithoutPagination, sort });
    },
    onFilter(filtersQuery) {
      const queryObject = { ...filtersQuery };

      if (this.sortByQuery) {
        queryObject.sort = this.sortByQuery;
      }

      if (this.queryAsObject.archived) {
        queryObject.archived = this.queryAsObject.archived;
      }

      if (this.queryAsObject.personal) {
        queryObject.personal = this.queryAsObject.personal;
      }

      this.trackEvent(this.filterEventName);

      this.visitUrlWithQueryObject(queryObject);
    },
  },
};
</script>

<template>
  <filtered-search-and-sort
    class="gl-border-b gl-w-full"
    :filtered-search-namespace="$options.filteredSearch.namespace"
    :filtered-search-tokens="filteredSearchTokens"
    :filtered-search-term-key="$options.filteredSearch.searchTermKey"
    :filtered-search-recent-searches-storage-key="$options.filteredSearch.recentSearchesStorageKey"
    :sort-options="sortOptions"
    :filtered-search-query="queryAsObject"
    :is-ascending="isAscending"
    :active-sort-option="activeSortOption"
    @filter="onFilter"
    @sort-direction-change="onSortDirectionChange"
    @sort-by-change="onSortByChange"
  />
</template>
