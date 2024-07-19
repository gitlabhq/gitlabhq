<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { getParameterByName, setUrlParams, queryToObject, visitUrl } from '~/lib/utils/url_utility';
import {
  SORT_QUERY_PARAM_NAME,
  ACTIVE_TAB_QUERY_PARAM_NAME,
  AVAILABLE_FILTERED_SEARCH_TOKENS,
  FILTERED_SEARCH_MAX_ROLE,
} from 'ee_else_ce/members/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

export default {
  name: 'MembersFilteredSearchBar',
  components: { FilteredSearchBar },
  availableTokens: AVAILABLE_FILTERED_SEARCH_TOKENS,
  searchButtonAttributes: { 'data-testid': 'search-button' },
  inject: {
    namespace: {},
    sourceId: {},
    canManageMembers: {},
    canFilterByEnterprise: { default: false },
    availableRoles: {},
  },
  data() {
    return {
      initialFilterValue: [],
    };
  },
  computed: {
    ...mapState({
      filteredSearchBar(state) {
        return state[this.namespace].filteredSearchBar;
      },
    }),
    tokens() {
      return this.$options.availableTokens.filter((token) => {
        if (token.type === FILTERED_SEARCH_MAX_ROLE.type) {
          const maxRoleToken = token;
          maxRoleToken.options = this.availableRoles;
        }

        if (
          Object.prototype.hasOwnProperty.call(token, 'requiredPermissions') &&
          !this[token.requiredPermissions]
        ) {
          return false;
        }

        if (token.type === 'user_type' && !gon.features?.serviceAccountsCrud) {
          return false;
        }

        return this.filteredSearchBar.tokens?.includes(token.type);
      });
    },
  },
  created() {
    const query = queryToObject(window.location.search);

    const tokens = this.tokens
      .filter((token) => query[token.type])
      .map((token) => ({
        type: token.type,
        value: {
          data: query[token.type],
          operator: '=',
        },
      }));

    if (query[this.filteredSearchBar.searchParam]) {
      tokens.push({
        type: FILTERED_SEARCH_TERM,
        value: {
          data: query[this.filteredSearchBar.searchParam],
        },
      });
    }

    this.initialFilterValue = tokens;
  },
  methods: {
    handleFilter(tokens) {
      const params = tokens.reduce((accumulator, token) => {
        const { type, value } = token;

        if (!type || !value) {
          return accumulator;
        }

        if (type === FILTERED_SEARCH_TERM) {
          if (value.data !== '') {
            const { searchParam } = this.filteredSearchBar;
            const { [searchParam]: searchParamValue } = accumulator;

            return {
              ...accumulator,
              [searchParam]: searchParamValue ? `${searchParamValue} ${value.data}` : value.data,
            };
          }
        } else {
          return {
            ...accumulator,
            [type]: value.data,
          };
        }

        return accumulator;
      }, {});

      const sortParamValue = getParameterByName(SORT_QUERY_PARAM_NAME);
      const activeTabParamValue = getParameterByName(ACTIVE_TAB_QUERY_PARAM_NAME);

      visitUrl(
        setUrlParams(
          {
            ...params,
            ...(sortParamValue && { [SORT_QUERY_PARAM_NAME]: sortParamValue }),
            ...(activeTabParamValue && { [ACTIVE_TAB_QUERY_PARAM_NAME]: activeTabParamValue }),
          },
          window.location.href,
          true,
        ),
      );
    },
  },
};
</script>

<template>
  <filtered-search-bar
    :namespace="sourceId.toString()"
    terms-as-tokens
    :tokens="tokens"
    :recent-searches-storage-key="filteredSearchBar.recentSearchesStorageKey"
    :search-input-placeholder="filteredSearchBar.placeholder"
    :initial-filter-value="initialFilterValue"
    :search-button-attributes="$options.searchButtonAttributes"
    :search-input-attributes="$options.searchInputAttributes"
    data-testid="members-filtered-search-bar"
    @onFilter="handleFilter"
  />
</template>
