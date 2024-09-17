<script>
import { GlFilteredSearchToken, GlButton, GlLink, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import ApprovalCount from 'ee_else_ce/merge_requests/components/approval_count.vue';
import { createAlert } from '~/alert';
import Api from '~/api';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN, STATUS_MERGED } from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import { fetchPolicies } from '~/lib/graphql';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { DEFAULT_PAGE_SIZE, mergeRequestListTabs } from '~/vue_shared/issuable/list/constants';
import {
  OPERATORS_IS,
  OPERATORS_IS_NOT,
  TOKEN_TITLE_APPROVED_BY,
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TITLE_DRAFT,
  TOKEN_TYPE_DRAFT,
  TOKEN_TITLE_TARGET_BRANCH,
  TOKEN_TYPE_TARGET_BRANCH,
  TOKEN_TITLE_SOURCE_BRANCH,
  TOKEN_TYPE_SOURCE_BRANCH,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TITLE_REVIEWER,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TITLE_MERGE_USER,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TITLE_LABEL,
  TOKEN_TYPE_LABEL,
  TOKEN_TITLE_RELEASE,
  TOKEN_TYPE_RELEASE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  deriveSortKey,
  getFilterTokens,
  getInitialPageParams,
  getSortOptions,
} from '~/issues/list/utils';
import {
  CREATED_DESC,
  PARAM_FIRST_PAGE_SIZE,
  PARAM_LAST_PAGE_SIZE,
  PARAM_PAGE_AFTER,
  PARAM_PAGE_BEFORE,
  PARAM_STATE,
  urlSortParams,
} from '~/issues/list/constants';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { i18n } from '../constants';
import getMergeRequestsQuery from '../queries/get_merge_requests.query.graphql';
import getMergeRequestsCountsQuery from '../queries/get_merge_requests_counts.query.graphql';
import searchLabelsQuery from '../queries/search_labels.query.graphql';
import MergeRequestStatistics from './merge_request_statistics.vue';
import MergeRequestMoreActionsDropdown from './more_actions_dropdown.vue';

const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');
const BranchToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/branch_token.vue');
const MilestoneToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue');
const LabelToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue');
const ReleaseToken = () => import('./tokens/release_client_search_token.vue');
const EmojiToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue');

export default {
  name: 'MergeRequestsListApp',
  i18n,
  mergeRequestListTabs,
  components: {
    GlButton,
    GlLink,
    GlIcon,
    IssuableList,
    CiIcon,
    MergeRequestStatistics,
    MergeRequestMoreActionsDropdown,
    ApprovalCount,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'autocompleteAwardEmojisPath',
    'fullPath',
    'hasAnyMergeRequests',
    'hasScopedLabelsFeature',
    'initialSort',
    'isPublicVisibilityRestricted',
    'isSignedIn',
    'newMergeRequestPath',
    'releasesEndpoint',
  ],
  data() {
    return {
      filterTokens: [],
      mergeRequests: [],
      mergeRequestCounts: {},
      mergeRequestsError: null,
      pageInfo: {},
      pageParams: {},
      sortKey: CREATED_DESC,
      state: STATUS_OPEN,
      pageSize: DEFAULT_PAGE_SIZE,
    };
  },
  apollo: {
    mergeRequests: {
      query: getMergeRequestsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.project.mergeRequests?.nodes ?? [];
      },
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      nextFetchPolicy: fetchPolicies.CACHE_FIRST,
      notifyOnNetworkStatusChange: true,
      result({ data }) {
        if (!data) {
          return;
        }
        this.pageInfo = data.project.mergeRequests?.pageInfo ?? {};
      },
      error(error) {
        this.mergeRequestsError = this.$options.i18n.errorFetchingMergeRequests;
        Sentry.captureException(error);
      },
      skip() {
        return !this.hasAnyMergeRequests || isEmpty(this.pageParams);
      },
    },
    mergeRequestCounts: {
      query: getMergeRequestsCountsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.project ?? {};
      },
      error(error) {
        this.mergeRequestsError = this.$options.i18n.errorFetchingCounts;
        Sentry.captureException(error);
      },
      skip() {
        return !this.hasAnyMergeRequests || isEmpty(this.pageParams);
      },
    },
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.fullPath,
        hideUsers: this.isPublicVisibilityRestricted && !this.isSignedIn,
        isSignedIn: this.isSignedIn,
        sort: this.sortKey,
        state: this.state,
        ...this.pageParams,
        ...this.apiFilterParams,
        search: this.searchQuery,
      };
    },
    hasSearch() {
      return Boolean(
        this.searchQuery ||
          Object.keys(this.urlFilterParams).length ||
          this.pageParams.afterCursor ||
          this.pageParams.beforeCursor,
      );
    },
    apiFilterParams() {
      return convertToApiParams(this.filterTokens);
    },
    urlFilterParams() {
      return convertToUrlParams(this.filterTokens);
    },
    searchQuery() {
      return convertToSearchQuery(this.filterTokens);
    },
    searchTokens() {
      const preloadedUsers = [];
      const tokens = [
        {
          type: TOKEN_TYPE_APPROVED_BY,
          title: TOKEN_TITLE_APPROVED_BY,
          icon: 'approval',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT,
          fullPath: this.fullPath,
          isProject: true,
          recentSuggestionsStorageKey: `${this.fullPath}-merge_requests-recent-tokens-approved_by`,
          preloadedUsers,
          multiSelect: false,
        },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT,
          fullPath: this.fullPath,
          isProject: true,
          recentSuggestionsStorageKey: `${this.fullPath}-merge-requests-recent-tokens-assignee`,
          preloadedUsers,
          multiSelect: false,
          unique: true,
        },
        {
          type: TOKEN_TYPE_REVIEWER,
          title: TOKEN_TITLE_REVIEWER,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT,
          fullPath: this.fullPath,
          isProject: true,
          recentSuggestionsStorageKey: `${this.fullPath}-merge-requests-recent-tokens-reviewer`,
          preloadedUsers,
          multiSelect: false,
          unique: true,
        },
        {
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: UserToken,
          dataType: 'user',
          defaultUsers: [],
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
          isProject: true,
          recentSuggestionsStorageKey: `${this.fullPath}-merge-requests-recent-tokens-author`,
          preloadedUsers,
          multiselect: false,
        },
        {
          type: TOKEN_TYPE_DRAFT,
          title: TOKEN_TITLE_DRAFT,
          icon: 'pencil-square',
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
          isProject: true,
          multiselect: false,
          options: [
            { value: 'yes', title: this.$options.i18n.yes },
            { value: 'no', title: this.$options.i18n.no },
          ],
          unique: true,
        },
        {
          type: TOKEN_TYPE_MERGE_USER,
          title: TOKEN_TITLE_MERGE_USER,
          icon: 'merge',
          token: UserToken,
          dataType: 'user',
          defaultUsers: [],
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
          isProject: true,
          recentSuggestionsStorageKey: `${this.fullPath}-merge_requests-recent-tokens-merged_by`,
          preloadedUsers,
          multiselect: false,
          unique: true,
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          token: MilestoneToken,
          operators: OPERATORS_IS,
          recentSuggestionsStorageKey: `${this.fullPath}-merge-requests-recent-tokens-milestone`,
          shouldSkipSort: true,
          fullPath: this.fullPath,
          isProject: true,
          multiselect: false,
          unique: true,
        },
        {
          type: TOKEN_TYPE_TARGET_BRANCH,
          title: TOKEN_TITLE_TARGET_BRANCH,
          icon: 'arrow-right',
          token: BranchToken,
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
          isProject: true,
          fetchBranches: this.fetchBranches,
        },
        {
          type: TOKEN_TYPE_SOURCE_BRANCH,
          title: TOKEN_TITLE_SOURCE_BRANCH,
          icon: 'branch',
          token: BranchToken,
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
          isProject: true,
          fetchBranches: this.fetchBranches,
        },
        {
          type: TOKEN_TYPE_LABEL,
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
          operators: OPERATORS_IS_NOT,
          fetchLabels: this.fetchLabels,
          recentSuggestionsStorageKey: `${this.fullPath}-merge_requests-recent-tokens-label`,
        },
        {
          type: TOKEN_TYPE_RELEASE,
          title: TOKEN_TITLE_RELEASE,
          icon: 'rocket',
          token: ReleaseToken,
          operators: OPERATORS_IS_NOT,
          releasesEndpoint: this.releasesEndpoint,
        },
      ];

      if (gon.current_user_id) {
        preloadedUsers.push({
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          name: gon.current_user_fullname,
          username: gon.current_username,
          avatar_url: gon.current_user_avatar_url,
        });
      }

      if (this.isSignedIn) {
        tokens.push({
          type: TOKEN_TYPE_MY_REACTION,
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          operators: OPERATORS_IS_NOT,
          unique: true,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: `${this.fullPath}-merge_requests-recent-tokens-my_reaction`,
        });
      }

      return tokens;
    },
    showPaginationControls() {
      return (
        this.mergeRequests.length > 0 &&
        (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage)
      );
    },
    sortOptions() {
      return getSortOptions({ hasManualSort: false });
    },
    tabCounts() {
      const { openedMergeRequests, closedMergeRequests, mergedMergeRequests, allMergeRequests } =
        this.mergeRequestCounts;
      return {
        [STATUS_OPEN]: openedMergeRequests?.count,
        [STATUS_MERGED]: mergedMergeRequests?.count,
        [STATUS_CLOSED]: closedMergeRequests?.count,
        [STATUS_ALL]: allMergeRequests?.count,
      };
    },
    urlParams() {
      return {
        sort: urlSortParams[this.sortKey],
        state: this.state,
        ...this.urlFilterParams,
        first_page_size: this.pageParams.firstPageSize,
        last_page_size: this.pageParams.lastPageSize,
        page_after: this.pageParams.afterCursor ?? undefined,
        page_before: this.pageParams.beforeCursor ?? undefined,
      };
    },
    isLoading() {
      return (
        this.$apollo.queries.mergeRequests.loading &&
        !this.$apollo.provider.clients.defaultClient.readQuery({
          query: getMergeRequestsQuery,
          variables: this.queryVariables,
        })
      );
    },
  },
  created() {
    this.updateData(this.initialSort);
  },
  methods: {
    fetchBranches(search) {
      return Api.branches(this.fullPath, search)
        .then((response) => {
          return response;
        })
        .catch(() => {
          createAlert({
            message: this.$options.i18n.errorFetchingBranches,
          });
        });
    },
    fetchEmojis() {
      return axios.get(this.autocompleteAwardEmojisPath);
    },
    fetchLabelsWithFetchPolicy(search, fetchPolicy = fetchPolicies.CACHE_FIRST) {
      return this.$apollo
        .query({
          query: searchLabelsQuery,
          variables: { fullPath: this.fullPath, search },
          fetchPolicy,
        })
        .then(({ data }) => data.project.labels.nodes)
        .then((labels) =>
          // TODO remove once we can search by title-only on the backend
          // https://gitlab.com/gitlab-org/gitlab/-/issues/346353
          labels.filter((label) => label.title.toLowerCase().includes(search.toLowerCase())),
        );
    },
    fetchLabels(search) {
      return this.fetchLabelsWithFetchPolicy(search);
    },
    getStatus(mergeRequest) {
      if (mergeRequest.state === STATUS_CLOSED) {
        return this.$options.i18n.closed;
      }
      if (mergeRequest.state === STATUS_MERGED) {
        return this.$options.i18n.merged;
      }
      return undefined;
    },
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }

      this.state = state;
      this.pageParams = getInitialPageParams(this.pageSize);

      this.$router.push({ query: this.urlParams });
    },
    handleNextPage() {
      this.pageParams = {
        afterCursor: this.pageInfo.endCursor,
        firstPageSize: this.pageSize,
      };
      scrollUp();

      this.$router.push({ query: this.urlParams });
    },
    handlePreviousPage() {
      this.pageParams = {
        beforeCursor: this.pageInfo.startCursor,
        lastPageSize: this.pageSize,
      };
      scrollUp();

      this.$router.push({ query: this.urlParams });
    },
    handleFilter(tokens) {
      this.filterTokens = tokens;
      this.pageParams = getInitialPageParams(this.pageSize);

      this.$router.push({ query: this.urlParams });
    },
    handleSort(sortKey) {
      if (this.sortKey === sortKey) {
        return;
      }

      this.sortKey = sortKey;
      this.pageParams = getInitialPageParams(this.pageSize);

      if (this.isSignedIn) {
        this.saveSortPreference(sortKey);
      }

      this.$router.push({ query: this.urlParams });
    },
    saveSortPreference(sortKey) {
      this.$apollo
        .mutate({
          mutation: setSortPreferenceMutation,
          variables: { input: { issuesSort: sortKey } },
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

      this.filterTokens = getFilterTokens(window.location.search);
      this.pageParams = getInitialPageParams(
        this.pageSize,
        isPositiveInteger(firstPageSize) ? parseInt(firstPageSize, 10) : undefined,
        isPositiveInteger(lastPageSize) ? parseInt(lastPageSize, 10) : undefined,
        getParameterByName(PARAM_PAGE_AFTER),
        getParameterByName(PARAM_PAGE_BEFORE),
      );
      this.sortKey = deriveSortKey({ sort, state });
      this.state = state || STATUS_OPEN;
    },
    isMergeRequestBroken(mergeRequest) {
      return (
        mergeRequest.commitCount === 0 ||
        !mergeRequest.sourceBranchExists ||
        !mergeRequest.targetBranchExists ||
        mergeRequest.conflicts
      );
    },
  },
  STATUS_OPEN,
};
</script>

<template>
  <issuable-list
    v-if="hasAnyMergeRequests"
    :namespace="fullPath"
    recent-searches-storage-key="merge_requests"
    :search-tokens="searchTokens"
    :has-scoped-labels-feature="hasScopedLabelsFeature"
    :initial-filter-value="filterTokens"
    :sort-options="sortOptions"
    :initial-sort-by="sortKey"
    :issuables="mergeRequests"
    :error="mergeRequestsError"
    :tabs="$options.mergeRequestListTabs"
    :current-tab="state"
    :tab-counts="tabCounts"
    :issuables-loading="isLoading"
    :show-pagination-controls="showPaginationControls"
    :default-page-size="pageSize"
    sync-filter-and-sort
    use-keyset-pagination
    :has-next-page="pageInfo.hasNextPage"
    :has-previous-page="pageInfo.hasPreviousPage"
    @click-tab="handleClickTab"
    @next-page="handleNextPage"
    @previous-page="handlePreviousPage"
    @sort="handleSort"
    @filter="handleFilter"
  >
    <template #nav-actions>
      <div class="gl-flex gl-gap-3">
        <gl-button
          v-if="newMergeRequestPath"
          variant="confirm"
          :href="newMergeRequestPath"
          data-testid="new-merge-request-button"
          data-event-tracking="click_new_merge_request_list"
        >
          {{ $options.i18n.newMergeRequest }}
        </gl-button>

        <merge-request-more-actions-dropdown />
      </div>
    </template>

    <template #status="{ issuable = {} }">
      {{ getStatus(issuable) }}
      <gl-link
        v-if="issuable.state === $options.STATUS_OPEN && isMergeRequestBroken(issuable)"
        v-gl-tooltip
        :href="issuable.webUrl"
        :title="__('Cannot be merged automatically')"
        data-testid="merge-request-cannot-merge"
      >
        <gl-icon name="warning-solid" class="gl-text-gray-900" />
      </gl-link>
    </template>

    <template #statistics="{ issuable = {} }">
      <merge-request-statistics :merge-request="issuable" />
    </template>

    <template #approval-status="{ issuable = {} }">
      <approval-count :merge-request="issuable" full-text />
    </template>

    <template #pipeline-status="{ issuable = {} }">
      <li
        v-if="issuable.headPipeline && issuable.headPipeline.detailedStatus"
        class="issuable-pipeline-status gl-hidden sm:gl-flex"
      >
        <ci-icon :status="issuable.headPipeline.detailedStatus" use-link show-tooltip />
      </li>
    </template>
  </issuable-list>
</template>
