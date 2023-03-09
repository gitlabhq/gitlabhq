<script>
import { setUrlParams, redirectTo, queryToObject, updateHistory } from '~/lib/utils/url_utility';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { FILTERED_SEARCH_TOKENS } from '~/admin/abuse_reports/constants';

export default {
  name: 'AbuseReportsFilteredSearchBar',
  components: { FilteredSearchBar },
  tokens: FILTERED_SEARCH_TOKENS,
  data() {
    return {
      initialFilterValue: [],
    };
  },
  created() {
    const query = queryToObject(window.location.search);

    // Backend shows open reports by default if status param is not specified.
    // To match that behavior, update the current URL to include status=open
    // query when no status query is specified on load.
    if (!query.status) {
      query.status = 'open';
      updateHistory({ url: setUrlParams(query), replace: true });
    }

    const tokens = this.$options.tokens
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
    handleFilter(tokens) {
      const params = tokens.reduce((accumulator, token) => {
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

      redirectTo(setUrlParams(params, window.location.href, true));
    },
  },
  filteredSearchNamespace: 'abuse_reports',
  recentSearchesStorageKey: 'abuse_reports',
};
</script>

<template>
  <filtered-search-bar
    :namespace="$options.filteredSearchNamespace"
    :tokens="$options.tokens"
    :recent-searches-storage-key="$options.recentSearchesStorageKey"
    :search-input-placeholder="__('Filter reports')"
    :initial-filter-value="initialFilterValue"
    @onFilter="handleFilter"
  />
</template>
