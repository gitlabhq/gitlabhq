<script>
import { defineAsyncComponent } from 'vue';
import { GlEmptyState, GlFilteredSearchToken } from '@gitlab/ui';
import emptySearchSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { isEqual } from 'lodash-es';
import axios from '~/lib/utils/axios_utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { STATUS_ALL, STATUS_CLOSED, STATUS_MERGED, STATUS_OPEN } from '~/issues/constants';
import { fetchPolicies } from '~/lib/graphql';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import { HTTP_STATUS_SERVICE_UNAVAILABLE } from '~/lib/utils/http_status';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import setSortPreferenceMutation from '~/issues/dashboard/queries/set_sort_preference.mutation.graphql';
import {
  OPERATOR_IS,
  OPERATOR_OR,
  OPERATORS_IS,
  OPERATORS_IS_NOT_OR,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TITLE_STATE,
  TOKEN_TYPE_STATE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  convertToApiParams,
  convertToUrlParams,
  deriveSortKey,
  getFilterTokens,
  getInitialPageParams,
  getSortOptions,
} from '~/work_items/list/utils';
import {
  CREATED_DESC,
  PARAM_FIRST_PAGE_SIZE,
  PARAM_LAST_PAGE_SIZE,
  PARAM_PAGE_AFTER,
  PARAM_PAGE_BEFORE,
  PARAM_SORT,
  PARAM_STATE,
  urlSortParams,
} from '~/work_items/list/constants';
import { i18n } from '~/merge_requests/list/constants';
import EmptyState from '~/merge_requests/list/components/empty_state.vue';
import getMergeRequestsQuery from '../queries/search/get_merge_requests.query.graphql';

const UserToken = defineAsyncComponent(
  () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue'),
);

const SEARCH_CLIENT = 'searchClient';

const SELECTIVE_TOKEN_TYPES = [TOKEN_TYPE_ASSIGNEE];

const SUPPORTED_TOKEN_TYPES = [...SELECTIVE_TOKEN_TYPES, TOKEN_TYPE_STATE];

const STATES = [STATUS_OPEN, STATUS_MERGED, STATUS_CLOSED, STATUS_ALL];
const UNSELECTIVE_VALUES = ['any', 'none'];

const comparableQuery = (query) =>
  Object.fromEntries(
    Object.entries(query)
      .filter(([, value]) => value !== undefined && value !== null && value !== '')
      .map(([key, value]) => [key, [value].flat().map(String)]),
  );

export default {
  name: 'MergeRequestDashboardSearchList',
  i18n: {
    ...i18n,
    noFilterTitle: __('Please select at least one filter to see results'),
    filterPlaceholder: __('Filter results'),
  },
  noTabs: [],
  STATUS_OPEN,
  emptySearchSvgPath,
  components: {
    EmptyState,
    GlEmptyState,
    IssuableList,
  },
  inject: [
    'autocompleteUsersPath',
    'hasScopedLabelsFeature',
    'initialSort',
    'isPublicVisibilityRestricted',
    'isSignedIn',
  ],
  data() {
    return {
      filterTokens: [],
      mergeRequests: [],
      mergeRequestsError: null,
      pageInfo: {},
      pageParams: {},
      pageSize: DEFAULT_PAGE_SIZE,
      searchTimeout: false,
      sortKey: CREATED_DESC,
    };
  },
  apollo: {
    mergeRequests: {
      client: SEARCH_CLIENT,
      query: getMergeRequestsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.mergeRequests?.nodes ?? [];
      },
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      notifyOnNetworkStatusChange: true,
      result({ data }) {
        if (!data) return;

        this.mergeRequestsError = null;
        this.searchTimeout = false;
        this.pageInfo = data.mergeRequests?.pageInfo ?? {};
      },
      error(error) {
        this.mergeRequestsError = this.$options.i18n.errorFetchingMergeRequests;
        this.mergeRequests = [];
        this.searchTimeout = error.networkError?.statusCode === HTTP_STATUS_SERVICE_UNAVAILABLE;

        if (!this.searchTimeout) Sentry.captureException(error);
      },
      skip() {
        return !this.hasFilters;
      },
    },
  },
  computed: {
    apiFilterParams() {
      return convertToApiParams(this.filterTokens);
    },
    urlFilterParams() {
      return convertToUrlParams(this.filterTokens);
    },
    hasFilters() {
      return this.filterTokens.some((token) => {
        if (!SELECTIVE_TOKEN_TYPES.includes(token.type)) return false;
        if (![OPERATOR_IS, OPERATOR_OR].includes(token.value?.operator)) return false;

        const values = [token.value?.data].flat();

        return (
          values.length > 0 &&
          values.every(
            (value) => value && !UNSELECTIVE_VALUES.includes(String(value).toLowerCase()),
          )
        );
      });
    },
    state() {
      return (
        this.filterTokens.find((token) => token.type === TOKEN_TYPE_STATE)?.value.data ??
        STATUS_OPEN
      );
    },
    queryVariables() {
      return {
        hideUsers: this.isPublicVisibilityRestricted && !this.isSignedIn,
        isSignedIn: this.isSignedIn,
        sort: this.existingSortKey,
        ...this.pageParams,
        ...this.apiFilterParams,
      };
    },
    existingSortKey() {
      const hasSortKey = this.sortOptions.some(
        (option) =>
          option.sortDirection.ascending === this.sortKey ||
          option.sortDirection.descending === this.sortKey,
      );

      return hasSortKey ? this.sortKey : CREATED_DESC;
    },
    isLoading() {
      return this.$apollo.queries.mergeRequests.loading;
    },
    showPaginationControls() {
      return (
        this.mergeRequests.length > 0 &&
        (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage)
      );
    },
    sortOptions() {
      return getSortOptions({
        hasManualSort: false,
        hasMergedDate: this.state === STATUS_MERGED,
        hasDueDate: false,
      });
    },
    urlParams() {
      return {
        sort: urlSortParams[this.sortKey],
        ...this.urlFilterParams,
        first_page_size: this.pageParams.firstPageSize,
        last_page_size: this.pageParams.lastPageSize,
        page_after: this.pageParams.afterCursor ?? undefined,
        page_before: this.pageParams.beforeCursor ?? undefined,
      };
    },
    searchTokens() {
      const preloadedUsers = [
        window.gon?.current_user_id && {
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          name: gon.current_user_fullname,
          username: gon.current_username,
          avatar_url: gon.current_user_avatar_url,
        },
      ].filter(Boolean);

      return [
        {
          type: TOKEN_TYPE_STATE,
          title: TOKEN_TITLE_STATE,
          icon: 'merge-request',
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          unique: true,
          options: [
            { value: STATUS_OPEN, title: __('Open') },
            { value: STATUS_MERGED, title: __('Merged') },
            { value: STATUS_CLOSED, title: __('Closed') },
            { value: STATUS_ALL, title: __('Any') },
          ],
        },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT_OR,
          fetchUsers: this.fetchUsers,
          preloadedUsers,
          recentSuggestionsStorageKey: 'dashboard-merge-requests-recent-tokens-assignee',
          multiSelect: true,
        },
      ];
    },
  },
  watch: {
    $route(newRoute, oldRoute) {
      if (newRoute.fullPath !== oldRoute.fullPath) this.updateData(this.initialSort);
    },
    hasFilters(hasFilters) {
      if (hasFilters) return;

      this.mergeRequests = [];
      this.pageInfo = {};
      this.mergeRequestsError = null;
      this.searchTimeout = false;
    },
  },
  created() {
    this.updateData(this.initialSort);
  },
  methods: {
    updateUrl() {
      const query = this.urlParams;

      if (isEqual(comparableQuery(query), comparableQuery(this.$route.query ?? {}))) return;

      this.$router.push({ query });
    },
    normalizeTokens(tokens) {
      const supported = tokens.filter((token) => SUPPORTED_TOKEN_TYPES.includes(token.type));
      const state =
        [supported.find((token) => token.type === TOKEN_TYPE_STATE)?.value?.data]
          .flat()
          .find((value) => STATES.includes(value)) ?? STATUS_OPEN;

      return [
        { type: TOKEN_TYPE_STATE, value: { data: state, operator: OPERATOR_IS } },
        ...supported.filter((token) => token.type !== TOKEN_TYPE_STATE),
      ];
    },
    fetchUsers(search) {
      return axios.get(this.autocompleteUsersPath, { params: { active: true, search } });
    },
    handleNextPage() {
      this.pageParams = {
        afterCursor: this.pageInfo.endCursor,
        firstPageSize: this.pageSize,
      };
      scrollUp();

      this.updateUrl();
    },
    handlePreviousPage() {
      this.pageParams = {
        beforeCursor: this.pageInfo.startCursor,
        lastPageSize: this.pageSize,
      };
      scrollUp();

      this.updateUrl();
    },
    handleFilter(tokens) {
      this.filterTokens = this.normalizeTokens(tokens);
      this.pageParams = getInitialPageParams(this.pageSize);

      this.updateUrl();
    },
    handleSort(sortKey) {
      if (this.sortKey === sortKey) return;

      this.sortKey = sortKey;
      this.pageParams = getInitialPageParams(this.pageSize);

      if (this.isSignedIn) this.saveSortPreference(sortKey);

      this.updateUrl();
    },
    handleDismissAlert() {
      this.mergeRequestsError = null;
    },
    saveSortPreference(sortKey) {
      this.$apollo
        .mutate({
          mutation: setSortPreferenceMutation,
          variables: { input: { mergeRequestsSort: sortKey } },
        })
        .then(({ data }) => {
          if (data.userPreferencesUpdate.errors.length) {
            throw new Error(data.userPreferencesUpdate.errors);
          }
        })
        .catch((error) => {
          Sentry.captureException(error);
        });
    },
    updateData(sort) {
      const firstPageSize = getParameterByName(PARAM_FIRST_PAGE_SIZE);
      const lastPageSize = getParameterByName(PARAM_LAST_PAGE_SIZE);
      const state = getParameterByName(PARAM_STATE);

      this.filterTokens = this.normalizeTokens(
        getFilterTokens(window.location.search, { includeStateToken: true }),
      );
      this.pageParams = getInitialPageParams(
        this.pageSize,
        isPositiveInteger(firstPageSize) ? parseInt(firstPageSize, 10) : undefined,
        isPositiveInteger(lastPageSize) ? parseInt(lastPageSize, 10) : undefined,
        getParameterByName(PARAM_PAGE_AFTER),
        getParameterByName(PARAM_PAGE_BEFORE),
      );
      this.sortKey = deriveSortKey({ sort: getParameterByName(PARAM_SORT) || sort, state });
    },
  },
};
</script>

<template>
  <issuable-list
    namespace="dashboard"
    recent-searches-storage-key="merge_requests"
    :search-tokens="searchTokens"
    :has-scoped-labels-feature="hasScopedLabelsFeature"
    :initial-filter-value="filterTokens"
    :sort-options="sortOptions"
    :initial-sort-by="existingSortKey"
    :issuables="mergeRequests"
    issuable-symbol="!"
    :error="mergeRequestsError"
    :search-input-placeholder="$options.i18n.filterPlaceholder"
    :tabs="$options.noTabs"
    :current-tab="state"
    :issuables-loading="isLoading"
    :show-pagination-controls="showPaginationControls"
    :default-page-size="pageSize"
    sync-filter-and-sort
    use-keyset-pagination
    :has-next-page="pageInfo.hasNextPage"
    :has-previous-page="pageInfo.hasPreviousPage"
    issuable-item-class="merge-request"
    :search-timeout="searchTimeout"
    always-allow-custom-empty-state
    class="-gl-mt-3"
    @next-page="handleNextPage"
    @previous-page="handlePreviousPage"
    @sort="handleSort"
    @filter="handleFilter"
    @dismiss-alert="handleDismissAlert"
  >
    <template #empty-state>
      <empty-state v-if="hasFilters" has-search />
      <gl-empty-state
        v-else
        :title="$options.i18n.noFilterTitle"
        :svg-path="$options.emptySearchSvgPath"
        data-testid="no-filter-empty-state"
      />
    </template>

    <template #search-timeout>
      <empty-state :search-timeout="searchTimeout" />
    </template>
  </issuable-list>
</template>
