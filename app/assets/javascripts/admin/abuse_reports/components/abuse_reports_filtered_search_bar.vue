<script>
import { setUrlParams, visitUrl, queryToObject, updateHistory } from '~/lib/utils/url_utility';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  FILTERED_SEARCH_TOKENS,
  DEFAULT_SORT_STATUS_OPEN,
  DEFAULT_SORT_STATUS_CLOSED,
} from '~/admin/abuse_reports/constants';

import {
  buildFilteredSearchCategoryToken,
  isValidStatus,
  isOpenStatus,
  isValidSortKey,
  sortOptions,
} from '~/admin/abuse_reports/utils';

export default {
  name: 'AbuseReportsFilteredSearchBar',
  components: { FilteredSearchBar },
  inject: ['categories'],
  data() {
    return {
      initialFilterValue: [],
      initialSortBy: DEFAULT_SORT_STATUS_OPEN,
    };
  },
  computed: {
    tokens() {
      return [...FILTERED_SEARCH_TOKENS, buildFilteredSearchCategoryToken(this.categories)];
    },
    query() {
      return queryToObject(window.location.search);
    },
    currentSortOptions() {
      return sortOptions(this.query.status);
    },
  },
  created() {
    const { query } = this;

    // Backend shows open reports by default if status param is not specified.
    // To match that behavior, update the current URL to include status=open
    // query when no status is specified on load.
    if (!isValidStatus(query.status)) {
      query.status = 'open';
      updateHistory({ url: setUrlParams(query), replace: true });
    }

    const sortKey = this.currentSortKey();
    this.initialSortBy = sortKey;

    const tokens = this.tokens
      .filter((token) => query[token.type])
      .map((token) => ({
        type: token.type,
        value: {
          data: query[token.type],
          operator: '=',
        },
      }));

    this.initialFilterValue = tokens;
  },
  methods: {
    currentSortKey() {
      const { status, sort } = this.query;

      if (!isValidSortKey(status, sort) || !sort) {
        return isOpenStatus(status) ? DEFAULT_SORT_STATUS_OPEN : DEFAULT_SORT_STATUS_CLOSED;
      }

      return sort;
    },
    handleFilter(tokens) {
      let params = tokens.reduce((accumulator, token) => {
        const { type, value } = token;

        // We don't support filtering reports by search term for now
        if (!value || !type || type === FILTERED_SEARCH_TERM) {
          return accumulator;
        }

        return {
          ...accumulator,
          [type]: value.data,
        };
      }, {});

      const sort = this.currentSortKey();

      if (sort) {
        params = { ...params, sort };
      }

      visitUrl(setUrlParams(params, window.location.href, true));
    },
    handleSort(sort) {
      const { page, ...query } = this.query;

      visitUrl(setUrlParams({ ...query, sort }, window.location.href, true));
    },
  },
  filteredSearchNamespace: 'abuse_reports',
  recentSearchesStorageKey: 'abuse_reports',
};
</script>

<template>
  <filtered-search-bar
    :namespace="$options.filteredSearchNamespace"
    :tokens="tokens"
    :recent-searches-storage-key="$options.recentSearchesStorageKey"
    :search-input-placeholder="__('Filter reports')"
    :initial-filter-value="initialFilterValue"
    :initial-sort-by="initialSortBy"
    :sort-options="currentSortOptions"
    data-testid="abuse-reports-filtered-search-bar"
    @onFilter="handleFilter"
    @onSort="handleSort"
  />
</template>
