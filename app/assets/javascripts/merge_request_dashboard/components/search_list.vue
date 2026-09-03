<script>
import { defineAsyncComponent } from 'vue';
import {
  GlEmptyState,
  GlFilteredSearchToken,
  GlIcon,
  GlLink,
  GlTooltipDirective,
} from '@gitlab/ui';
import emptySearchSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { isEqual } from 'lodash-es';
import ApprovalCount from 'ee_else_ce/merge_requests/components/approval_count.vue';
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
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import setSortPreferenceMutation from '~/issues/dashboard/queries/set_sort_preference.mutation.graphql';
import {
  OPERATOR_IS,
  OPERATOR_OR,
  OPERATORS_IS,
  OPERATORS_IS_NOT,
  OPERATORS_IS_NOT_OR,
  TOKEN_TITLE_APPROVED_BY,
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TITLE_DRAFT,
  TOKEN_TYPE_DRAFT,
  TOKEN_TITLE_LABEL,
  TOKEN_TYPE_LABEL,
  TOKEN_TITLE_MERGED_AFTER,
  TOKEN_TYPE_MERGED_AFTER,
  TOKEN_TITLE_MERGED_BEFORE,
  TOKEN_TYPE_MERGED_BEFORE,
  TOKEN_TITLE_MERGE_USER,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TITLE_REVIEWER,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TITLE_STATE,
  TOKEN_TYPE_STATE,
  TOKEN_TITLE_SUBSCRIBED,
  TOKEN_TYPE_SUBSCRIBED,
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
import { AutocompleteCache } from '~/merge_requests/utils/autocomplete_cache';
import { i18n } from '~/merge_requests/list/constants';
import DiscussionsBadge from '~/merge_requests/list/components/discussions_badge.vue';
import EmptyState from '~/merge_requests/list/components/empty_state.vue';
import MergeRequestReviewers from '~/merge_requests/list/components/merge_request_reviewers.vue';
import MergeRequestStatistics from '~/merge_requests/list/components/merge_request_statistics.vue';
import getMergeRequestsQuery from 'ee_else_ce/merge_request_dashboard/queries/search/get_merge_requests.query.graphql';
import getMergeRequestsApprovalsQuery from '../queries/search/get_merge_requests_approvals.query.graphql';

const UserToken = defineAsyncComponent(
  () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue'),
);
const MilestoneToken = defineAsyncComponent(
  () => import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue'),
);
const LabelToken = defineAsyncComponent(
  () => import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue'),
);
const EmojiToken = defineAsyncComponent(
  () => import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue'),
);
const DateToken = defineAsyncComponent(
  () => import('~/vue_shared/components/filtered_search_bar/tokens/date_token.vue'),
);

const SEARCH_CLIENT = 'searchClient';

const SELECTIVE_TOKEN_TYPES = [
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MY_REACTION,
];

const SUPPORTED_TOKEN_TYPES = [
  ...SELECTIVE_TOKEN_TYPES,
  TOKEN_TYPE_STATE,
  TOKEN_TYPE_DRAFT,
  TOKEN_TYPE_MERGED_BEFORE,
  TOKEN_TYPE_MERGED_AFTER,
  TOKEN_TYPE_SUBSCRIBED,
];

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
    ApprovalCount,
    CiIcon,
    DiscussionsBadge,
    EmptyState,
    GlEmptyState,
    GlIcon,
    GlLink,
    IssuableList,
    IssuableMilestone,
    MergeRequestReviewers,
    MergeRequestStatistics,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'autocompleteAwardEmojisPath',
    'autocompleteUsersPath',
    'dashboardLabelsPath',
    'dashboardMilestonesPath',
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
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    mergeRequestApprovals: {
      client: SEARCH_CLIENT,
      query: getMergeRequestsApprovalsQuery,
      variables() {
        return this.queryVariables;
      },
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      manual: true,
      result() {},
      error(error) {
        if (error.networkError?.statusCode !== HTTP_STATUS_SERVICE_UNAVAILABLE) {
          Sentry.captureException(error);
        }
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
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: UserToken,
          dataType: 'user',
          defaultUsers: [],
          fetchUsers: this.fetchUsers,
          preloadedUsers,
          recentSuggestionsStorageKey: 'dashboard-merge-requests-recent-tokens-author',
          multiSelect: false,
          unique: true,
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
        {
          type: TOKEN_TYPE_REVIEWER,
          title: TOKEN_TITLE_REVIEWER,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          fetchUsers: this.fetchUsers,
          preloadedUsers,
          recentSuggestionsStorageKey: 'dashboard-merge-requests-recent-tokens-reviewer',
          multiSelect: false,
          unique: true,
        },
        {
          type: TOKEN_TYPE_APPROVED_BY,
          title: TOKEN_TITLE_APPROVED_BY,
          icon: 'approval',
          token: UserToken,
          dataType: 'user',
          fetchUsers: this.fetchUsers,
          preloadedUsers,
          recentSuggestionsStorageKey: 'dashboard-merge-requests-recent-tokens-approved-by',
          multiSelect: false,
        },
        {
          type: TOKEN_TYPE_MERGE_USER,
          title: TOKEN_TITLE_MERGE_USER,
          icon: 'merge',
          token: UserToken,
          dataType: 'user',
          defaultUsers: [],
          operators: OPERATORS_IS,
          fetchUsers: this.fetchUsers,
          preloadedUsers,
          recentSuggestionsStorageKey: 'dashboard-merge-requests-recent-tokens-merge-user',
          multiSelect: false,
          unique: true,
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          token: MilestoneToken,
          fetchMilestones: this.fetchMilestones,
          recentSuggestionsStorageKey: 'dashboard-merge-requests-recent-tokens-milestone',
          shouldSkipSort: true,
          multiSelect: false,
          unique: true,
        },
        {
          type: TOKEN_TYPE_LABEL,
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
          operators: OPERATORS_IS_NOT,
          fetchLabels: this.fetchLabels,
          recentSuggestionsStorageKey: 'dashboard-merge-requests-recent-tokens-label',
        },
        this.isSignedIn && {
          type: TOKEN_TYPE_MY_REACTION,
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          unique: true,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: 'dashboard-merge-requests-recent-tokens-my-reaction',
        },
        {
          type: TOKEN_TYPE_DRAFT,
          title: TOKEN_TITLE_DRAFT,
          icon: 'pencil-square',
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          unique: true,
          options: [
            { icon: 'check', value: 'yes', title: this.$options.i18n.yes },
            { icon: 'close', value: 'no', title: this.$options.i18n.no },
          ],
        },
        this.state === STATUS_MERGED && {
          type: TOKEN_TYPE_MERGED_BEFORE,
          title: TOKEN_TITLE_MERGED_BEFORE,
          icon: 'clock',
          token: DateToken,
          operators: OPERATORS_IS,
          unique: true,
        },
        this.state === STATUS_MERGED && {
          type: TOKEN_TYPE_MERGED_AFTER,
          title: TOKEN_TITLE_MERGED_AFTER,
          icon: 'clock',
          token: DateToken,
          operators: OPERATORS_IS,
          unique: true,
        },
        this.isSignedIn && {
          type: TOKEN_TYPE_SUBSCRIBED,
          title: TOKEN_TITLE_SUBSCRIBED,
          icon: 'notifications',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            {
              icon: 'notifications',
              value: 'EXPLICITLY_SUBSCRIBED',
              title: __('Explicitly subscribed'),
            },
            {
              icon: 'notifications-off',
              value: 'EXPLICITLY_UNSUBSCRIBED',
              title: __('Explicitly unsubscribed'),
            },
          ],
        },
      ].filter(Boolean);
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
    this.autocompleteCache = new AutocompleteCache();
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
    fetchEmojis(search) {
      return this.autocompleteCache.fetch({
        url: this.autocompleteAwardEmojisPath,
        searchProperty: 'name',
        search,
      });
    },
    fetchLabels(search) {
      return this.autocompleteCache.fetch({
        url: this.dashboardLabelsPath,
        searchProperty: 'title',
        search,
      });
    },
    fetchMilestones(search) {
      return this.autocompleteCache.fetch({
        url: this.dashboardMilestonesPath,
        searchProperty: 'title',
        search,
      });
    },
    fetchUsers(search) {
      return axios.get(this.autocompleteUsersPath, { params: { active: true, search } });
    },
    getStatus(mergeRequest) {
      if (mergeRequest.state === STATUS_CLOSED) return this.$options.i18n.closed;
      if (mergeRequest.state === STATUS_MERGED) return this.$options.i18n.merged;

      return undefined;
    },
    getReviewers(mergeRequest) {
      return mergeRequest.reviewers?.nodes || [];
    },
    isMergeRequestBroken(mergeRequest) {
      return (
        mergeRequest.commitCount === 0 ||
        !mergeRequest.sourceBranchExists ||
        !mergeRequest.targetBranchExists ||
        mergeRequest.conflicts
      );
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
    <template #status="{ issuable = {} }">
      {{ getStatus(issuable) }}
      <gl-link
        v-if="issuable.state === $options.STATUS_OPEN && isMergeRequestBroken(issuable)"
        v-gl-tooltip
        :href="issuable.webPath"
        :title="__('Cannot be merged automatically')"
        data-testid="merge-request-cannot-merge"
      >
        <gl-icon name="warning-solid" variant="strong" />
      </gl-link>
    </template>

    <template #timeframe="{ issuable = {} }">
      <issuable-milestone v-if="issuable.milestone" :milestone="issuable.milestone" />
    </template>

    <template #discussions="{ issuable = {} }">
      <li
        v-if="issuable.resolvableDiscussionsCount"
        class="!gl-mr-0 gl-hidden @sm/panel:gl-inline-flex"
      >
        <discussions-badge :merge-request="issuable" />
      </li>
    </template>

    <template #statistics="{ issuable = {} }">
      <li
        v-if="issuable.upvotes || issuable.downvotes"
        class="!gl-mr-0 gl-hidden @sm/panel:gl-inline-flex"
      >
        <merge-request-statistics :merge-request="issuable" class="gl-flex" />
      </li>
    </template>

    <template #approval-status="{ issuable = {} }">
      <li
        v-if="
          issuable.approvalsRequired || (issuable.approvedBy && issuable.approvedBy.nodes.length)
        "
        class="!gl-mr-0"
      >
        <approval-count :merge-request="issuable" full-text class="gl-mt-1" />
      </li>
    </template>

    <template #pipeline-status="{ issuable = {} }">
      <li
        v-if="issuable.headPipeline && issuable.headPipeline.detailedStatus"
        class="issuable-pipeline-status !gl-mr-0 gl-hidden @sm/panel:gl-flex"
      >
        <ci-icon :status="issuable.headPipeline.detailedStatus" use-link show-tooltip />
      </li>
    </template>

    <template #reviewers="{ issuable = {} }">
      <li v-if="getReviewers(issuable).length" class="issuable-reviewers !gl-mr-0">
        <merge-request-reviewers
          :reviewers="getReviewers(issuable)"
          :icon-size="16"
          :max-visible="4"
          class="gl-flex gl-items-center"
        />
      </li>
    </template>

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
