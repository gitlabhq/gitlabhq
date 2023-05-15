<script>
import { setUrlParams, redirectTo, queryToObject, updateHistory } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  FILTERED_SEARCH_TOKENS,
  DEFAULT_SORT,
  SORT_OPTIONS,
  isValidSortKey,
} from '~/admin/abuse_reports/constants';
import { buildFilteredSearchCategoryToken, isValidStatus } from '~/admin/abuse_reports/utils';

export default {
  name: 'AbuseReportsFilteredSearchBar',
  components: { FilteredSearchBar },
  sortOptions: SORT_OPTIONS,
  inject: ['categories'],
  data() {
    return {
      initialFilterValue: [],
      initialSortBy: DEFAULT_SORT,
    };
  },
  computed: {
    tokens() {
      return [...FILTERED_SEARCH_TOKENS, buildFilteredSearchCategoryToken(this.categories)];
    },
  },
  created() {
    const query = queryToObject(window.location.search);

    // Backend shows open reports by default if status param is not specified.
    // To match that behavior, update the current URL to include status=open
    // query when no status query is specified on load.
    if (!isValidStatus(query.status)) {
      query.status = 'open';
      updateHistory({ url: setUrlParams(query), replace: true });
    }

    const sort = this.currentSortKey();
    if (sort) {
      this.initialSortBy = query.sort;
    }

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
      const { sort } = queryToObject(window.location.search);

      return isValidSortKey(sort) ? sort : undefined;
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

      redirectTo(setUrlParams(params, window.location.href, true)); // eslint-disable-line import/no-deprecated
    },
    handleSort(sort) {
      const { page, ...query } = queryToObject(window.location.search);

      redirectTo(setUrlParams({ ...query, sort }, window.location.href, true)); // eslint-disable-line import/no-deprecated
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
    :sort-options="$options.sortOptions"
    data-testid="abuse-reports-filtered-search-bar"
    @onFilter="handleFilter"
    @onSort="handleSort"
  />
</template>
