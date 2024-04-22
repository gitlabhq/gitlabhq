<script>
import { isEqual } from 'lodash';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  EXPLORE_SORTING_ITEMS,
  SORTING_ITEM_NAME,
  EXPLORE_FILTERED_SEARCH_TERM_KEY,
  EXPLORE_FILTERED_SEARCH_NAMESPACE,
} from '../constants';
import GroupsService from '../service/groups_service';
import GroupsStore from '../store/groups_store';
import eventHub from '../event_hub';
import GroupsApp from './app.vue';
import EmptyState from './empty_states/groups_explore_empty_state.vue';

export default {
  filteredSearch: {
    tokens: [],
    namespace: EXPLORE_FILTERED_SEARCH_NAMESPACE,
    recentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
    searchTermKey: EXPLORE_FILTERED_SEARCH_TERM_KEY,
  },
  components: {
    FilteredSearchAndSort,
    GroupsApp,
    EmptyState,
  },
  inject: ['endpoint', 'initialSort'],
  data() {
    return {
      service: new GroupsService(this.endpoint),
      store: new GroupsStore({ hideProjects: true }),
    };
  },
  computed: {
    sortByQuery() {
      return this.$route.query?.sort;
    },
    sortBy() {
      return this.sortByQuery || this.initialSort;
    },
    search() {
      return this.$route.query?.filter || '';
    },
    activeSortItem() {
      return (
        EXPLORE_SORTING_ITEMS.find(
          (sortItem) => sortItem.asc === this.sortBy || sortItem.desc === this.sortBy,
        ) || SORTING_ITEM_NAME
      );
    },
    activeSortOption() {
      return {
        value: this.isAscending ? this.activeSortItem.asc : this.activeSortItem.desc,
        text: this.activeSortItem.label,
      };
    },
    isAscending() {
      if (!this.sortBy) {
        return true;
      }

      return this.activeSortItem.asc === this.sortBy;
    },
    sortOptions() {
      return EXPLORE_SORTING_ITEMS.map((sortItem) => {
        return {
          value: this.isAscending ? sortItem.asc : sortItem.desc,
          text: sortItem.label,
        };
      });
    },
    routeQueryWithoutPagination() {
      const { page, ...routeQuery } = this.$route.query;

      return routeQuery;
    },
  },
  methods: {
    pushQuery(query) {
      const currentQuery = this.$route.query;

      if (isEqual(currentQuery, query)) {
        return;
      }

      this.$router.push({ query });
    },
    onSortDirectionChange(isAscending) {
      const sortBy = isAscending ? this.activeSortItem.asc : this.activeSortItem.desc;

      eventHub.$emit('fetchFilteredAndSortedGroups', {
        filterGroupsBy: this.search,
        sortBy,
      });
      this.pushQuery({ ...this.routeQueryWithoutPagination, sort: sortBy });
    },
    onSortByChange(sortBy) {
      eventHub.$emit('fetchFilteredAndSortedGroups', {
        filterGroupsBy: this.search,
        sortBy,
      });
      this.pushQuery({ ...this.routeQueryWithoutPagination, sort: sortBy });
    },
    onFilter(filtersQuery) {
      const search = filtersQuery[EXPLORE_FILTERED_SEARCH_TERM_KEY];

      eventHub.$emit('fetchFilteredAndSortedGroups', {
        filterGroupsBy: search,
        sortBy: this.sortBy,
      });
      this.pushQuery({
        ...(search ? { [EXPLORE_FILTERED_SEARCH_TERM_KEY]: search } : {}),
        sort: this.sortByQuery,
      });
    },
  },
};
</script>

<template>
  <div>
    <filtered-search-and-sort
      :filtered-search-namespace="$options.filteredSearch.namespace"
      :filtered-search-tokens="$options.filteredSearch.tokens"
      :filtered-search-term-key="$options.filteredSearch.searchTermKey"
      :filtered-search-recent-searches-storage-key="
        $options.filteredSearch.recentSearchesStorageKey
      "
      :filtered-search-query="$route.query"
      :is-ascending="isAscending"
      :sort-options="sortOptions"
      :active-sort-option="activeSortOption"
      @filter="onFilter"
      @sort-direction-change="onSortDirectionChange"
      @sort-by-change="onSortByChange"
    />
    <groups-app :service="service" :store="store">
      <template #empty-state>
        <empty-state />
      </template>
    </groups-app>
  </div>
</template>
