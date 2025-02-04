<script>
import { GlFilteredSearchToken, GlButton, GlLink, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import ApprovalCount from 'ee_else_ce/merge_requests/components/approval_count.vue';
import { sprintf, __ } from '~/locale';
import Api from '~/api';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN, STATUS_MERGED } from '~/issues/constants';
import { fetchPolicies } from '~/lib/graphql';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName, mergeUrlParams } from '~/lib/utils/url_utility';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import { DEFAULT_PAGE_SIZE, mergeRequestListTabs } from '~/vue_shared/issuable/list/constants';
import {
  OPERATORS_IS,
  OPERATORS_IS_NOT,
  TOKEN_TITLE_APPROVED_BY,
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TITLE_APPROVER,
  TOKEN_TYPE_APPROVER,
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
  TOKEN_TITLE_DEPLOYED_BEFORE,
  TOKEN_TYPE_DEPLOYED_BEFORE,
  TOKEN_TITLE_DEPLOYED_AFTER,
  TOKEN_TYPE_DEPLOYED_AFTER,
  TOKEN_TYPE_ENVIRONMENT,
  TOKEN_TITLE_ENVIRONMENT,
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
  PARAM_SORT,
} from '~/issues/list/constants';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import MergeRequestReviewers from '~/issuable/components/merge_request_reviewers.vue';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import issuableEventHub from '~/issues/list/eventhub';
import searchLabelsQuery from '~/issues/list/queries/search_labels.query.graphql';
import { AutocompleteCache } from '../../utils/autocomplete_cache';
import { i18n, BRANCH_LIST_REFRESH_INTERVAL } from '../constants';
import MergeRequestStatistics from './merge_request_statistics.vue';
import MergeRequestMoreActionsDropdown from './more_actions_dropdown.vue';
import EmptyState from './empty_state.vue';
import DiscussionsBadge from './discussions_badge.vue';

const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');
const BranchToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/branch_token.vue');
const MilestoneToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue');
const LabelToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue');
const ReleaseToken = () => import('./tokens/release_client_search_token.vue');
const EnvironmentToken = () => import('./tokens/environment_token.vue');
const EmojiToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue');
const DateToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/date_token.vue');

function cacheIsExpired(cacheAge, compareTo = Date.now()) {
  return cacheAge + BRANCH_LIST_REFRESH_INTERVAL <= compareTo;
}

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
    MergeRequestReviewers,
    ApprovalCount,
    EmptyState,
    IssuableMilestone,
    IssuableByEmail,
    DiscussionsBadge,
    NewResourceDropdown: () =>
      import('~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    autocompleteAwardEmojisPat: { default: '' },
    fullPath: { default: '' },
    hasAnyMergeRequests: { default: false },
    hasScopedLabelsFeature: { default: false },
    initialSort: { default: '' },
    isPublicVisibilityRestricted: { default: false },
    isSignedIn: { default: false },
    newMergeRequestPath: { default: '' },
    releasesEndpoint: { default: '' },
    canBulkUpdate: { default: false },
    environmentNamesPath: { default: '' },
    mergeTrainsPath: { default: undefined },
    defaultBranch: { default: '' },
    initialEmail: { default: '' },
    getMergeRequestsQuery: { default: undefined },
    getMergeRequestsCountsQuery: { default: undefined },
    getMergeRequestsApprovalsQuery: { default: undefined },
    isProject: { default: true },
    groupId: { default: undefined },
    showNewResourceDropdown: { default: undefined },
  },
  data() {
    return {
      namespaceId: null,
      branchCacheAges: {},
      filterTokens: [],
      mergeRequests: [],
      mergeRequestCounts: {},
      mergeRequestsError: null,
      pageInfo: {},
      pageParams: {},
      sortKey: CREATED_DESC,
      state: STATUS_OPEN,
      pageSize: DEFAULT_PAGE_SIZE,
      showBulkEditSidebar: false,
    };
  },
  apollo: {
    mergeRequests: {
      query() {
        return this.getMergeRequestsQuery;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.namespace.mergeRequests?.nodes ?? [];
      },
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      nextFetchPolicy: fetchPolicies.CACHE_FIRST,
      notifyOnNetworkStatusChange: true,
      result({ data }) {
        if (!data) {
          return;
        }
        this.namespaceId = getIdFromGraphQLId(data.namespace.id);
        this.pageInfo = data.namespace.mergeRequests?.pageInfo ?? {};
      },
      error(error) {
        this.mergeRequestsError = this.$options.i18n.errorFetchingMergeRequests;
        Sentry.captureException(error);
      },
      skip() {
        return !this.hasAnyMergeRequests || isEmpty(this.pageParams) || !this.getMergeRequestsQuery;
      },
    },
    // The approvals data gets loaded in a seperate request so that if it timesout due to
    // the large amount of data getting processed on the backend we can still render the
    // merge request list.
    // The data here gets stored in cache and then loaded through the `@client` directives
    // in the merge request query.
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    mergeRequestApprovals: {
      query() {
        return this.getMergeRequestsApprovalsQuery;
      },
      variables() {
        return this.queryVariables;
      },
      skip() {
        return (
          !this.hasAnyMergeRequests ||
          isEmpty(this.pageParams) ||
          !this.getMergeRequestsApprovalsQuery
        );
      },
      manual: true,
      result() {},
    },
    mergeRequestCounts: {
      query() {
        return this.getMergeRequestsCountsQuery;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.namespace ?? {};
      },
      error(error) {
        this.mergeRequestsError = this.$options.i18n.errorFetchingCounts;
        Sentry.captureException(error);
      },
      skip() {
        return (
          !this.hasAnyMergeRequests || isEmpty(this.pageParams) || !this.getMergeRequestsCountsQuery
        );
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
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: UserToken,
          dataType: 'user',
          defaultUsers: [],
          fullPath: this.fullPath,
          isProject: this.isProject,
          recentSuggestionsStorageKey: `${this.fullPath}-merge-requests-recent-tokens-author`,
          preloadedUsers,
          multiselect: false,
        },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          fullPath: this.fullPath,
          isProject: this.isProject,
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
          fullPath: this.fullPath,
          isProject: this.isProject,
          recentSuggestionsStorageKey: `${this.fullPath}-merge-requests-recent-tokens-reviewer`,
          preloadedUsers,
          multiSelect: false,
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
          isProject: this.isProject,
          recentSuggestionsStorageKey: `${this.fullPath}-merge_requests-recent-tokens-merged_by`,
          preloadedUsers,
          multiselect: false,
          unique: true,
        },
        {
          type: TOKEN_TYPE_APPROVER,
          title: TOKEN_TITLE_APPROVER,
          icon: 'approval',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
          isProject: this.isProject,
          recentSuggestionsStorageKey: `${this.fullPath}-merge_requests-recent-tokens-approvers`,
          preloadedUsers,
          multiSelect: false,
        },
        {
          type: TOKEN_TYPE_APPROVED_BY,
          title: TOKEN_TITLE_APPROVED_BY,
          icon: 'approval',
          token: UserToken,
          dataType: 'user',
          fullPath: this.fullPath,
          isProject: this.isProject,
          recentSuggestionsStorageKey: `${this.fullPath}-merge_requests-recent-tokens-approved_by`,
          preloadedUsers,
          multiSelect: false,
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          token: MilestoneToken,
          recentSuggestionsStorageKey: `${this.fullPath}-merge-requests-recent-tokens-milestone`,
          shouldSkipSort: true,
          fullPath: this.fullPath,
          isProject: this.isProject,
          multiselect: false,
          unique: true,
        },
        {
          type: TOKEN_TYPE_LABEL,
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
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
        this.isSignedIn && {
          type: TOKEN_TYPE_MY_REACTION,
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          unique: true,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: `${this.fullPath}-merge_requests-recent-tokens-my_reaction`,
        },
        {
          type: TOKEN_TYPE_DRAFT,
          title: TOKEN_TITLE_DRAFT,
          icon: 'pencil-square',
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
          isProject: this.isProject,
          multiselect: false,
          options: [
            { value: 'yes', title: this.$options.i18n.yes },
            { value: 'no', title: this.$options.i18n.no },
          ],
          unique: true,
        },
        {
          type: TOKEN_TYPE_TARGET_BRANCH,
          title: TOKEN_TITLE_TARGET_BRANCH,
          icon: 'arrow-right',
          token: BranchToken,
          fullPath: this.fullPath,
          isProject: this.isProject,
          fetchBranches: this.fetchTargetBranches,
        },
        {
          type: TOKEN_TYPE_SOURCE_BRANCH,
          title: TOKEN_TITLE_SOURCE_BRANCH,
          icon: 'branch',
          token: BranchToken,
          fullPath: this.fullPath,
          isProject: this.isProject,
          fetchBranches: this.fetchSourceBranches,
        },
        {
          type: TOKEN_TYPE_ENVIRONMENT,
          title: TOKEN_TITLE_ENVIRONMENT,
          icon: 'environment',
          token: EnvironmentToken,
          operators: OPERATORS_IS,
          multiselect: false,
          unique: true,
          environmentsEndpoint: this.environmentNamesPath,
        },
        {
          type: TOKEN_TYPE_DEPLOYED_BEFORE,
          title: TOKEN_TITLE_DEPLOYED_BEFORE,
          icon: 'clock',
          token: DateToken,
          operators: OPERATORS_IS,
        },
        {
          type: TOKEN_TYPE_DEPLOYED_AFTER,
          title: TOKEN_TITLE_DEPLOYED_AFTER,
          icon: 'clock',
          token: DateToken,
          operators: OPERATORS_IS,
        },
      ].filter(Boolean);
    },
    showPaginationControls() {
      return (
        this.mergeRequests.length > 0 &&
        (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage)
      );
    },
    sortOptions() {
      return getSortOptions({ hasManualSort: false, hasMergedDate: this.state === STATUS_MERGED });
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
          query: this.getMergeRequestsQuery,
          variables: this.queryVariables,
        })
      );
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
    },
    isBulkEditButtonDisabled() {
      return this.showBulkEditSidebar || !this.mergeRequests.length;
    },
    resourceDropdownQueryVariables() {
      return { fullPath: this.fullPath };
    },
    currentTabCount() {
      return this.tabCounts[this.state] || 0;
    },
  },
  watch: {
    $route(newValue, oldValue) {
      if (newValue.fullPath !== oldValue.fullPath) {
        this.updateData(getParameterByName(PARAM_SORT));
      }
    },
    state: {
      handler(val) {
        document
          .querySelector('.js-status-dropdown-container')
          ?.classList.toggle('gl-hidden', val === STATUS_MERGED);
      },
      immediate: true,
    },
  },
  created() {
    this.updateData(this.initialSort);
    this.autocompleteCache = new AutocompleteCache();
  },
  mounted() {
    issuableEventHub.$on('issuables:toggleBulkEdit', this.toggleBulkEditSidebar);
  },
  beforeDestroy() {
    issuableEventHub.$off('issuables:toggleBulkEdit', this.toggleBulkEditSidebar);
  },
  methods: {
    getBranchPath(branchType = 'other') {
      const typeUrls = {
        source: '/-/autocomplete/merge_request_source_branches.json',
        target: '/-/autocomplete/merge_request_target_branches.json',
        other: Api.buildUrl(Api.createBranchPath).replace(':id', encodeURIComponent(this.fullPath)),
      };
      const url = typeUrls[branchType];

      return url && this.namespaceId
        ? mergeUrlParams({ [this.isProject ? 'project_id' : 'group_id']: this.namespaceId }, url)
        : typeUrls.other;
    },
    async updateBranchCache(branchType, path) {
      const lastCheck = this.branchCacheAges[branchType];

      if (cacheIsExpired(lastCheck)) {
        await this.autocompleteCache.updateLocalCache(path);
      }
    },
    async fetchBranches(type = 'other', search) {
      const branchPath = this.getBranchPath(type);
      const cacheAge = this.branchCacheAges[type];
      const runTime = Date.now();

      await this.updateBranchCache(type, branchPath);

      const fetch = this.autocompleteCache.fetch({
        mutator: (branchList) =>
          branchList.map((branch, index) => ({
            ...branch,
            name: branch.name || branch.title,
            id: index,
          })),
        formatter: (results) => ({ data: results }),
        url: branchPath,
        searchProperty: 'name',
        search,
      });

      fetch
        .then(() => {
          if (!cacheAge || cacheIsExpired(cacheAge, runTime)) {
            this.branchCacheAges[type] = Date.now();
          }
        })
        .catch(() => {
          // An error has occurred, but there's nothing the user can do about it, so... we're swallowing it.
        });

      return fetch;
    },
    fetchTargetBranches(search) {
      return this.fetchBranches('target', search);
    },
    fetchSourceBranches(search) {
      return this.fetchBranches('source', search);
    },
    fetchEmojis(search) {
      return this.autocompleteCache.fetch({
        url: this.autocompleteAwardEmojisPath,
        cacheName: 'emojis',
        searchProperty: 'name',
        search,
      });
    },
    fetchLabelsWithFetchPolicy(search, fetchPolicy = fetchPolicies.CACHE_FIRST) {
      return this.$apollo
        .query({
          query: searchLabelsQuery,
          variables: { fullPath: this.fullPath, search, isProject: this.isProject },
          fetchPolicy,
        })
        .then(({ data }) => (data.project || data.group).labels.nodes)
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
    getReviewers(issuable) {
      return issuable.reviewers?.nodes || [];
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
    toggleBulkEditSidebar(showBulkEditSidebar) {
      this.showBulkEditSidebar = showBulkEditSidebar;
    },
    async handleBulkUpdateClick() {
      if (!this.hasInitBulkEdit) {
        const bulkUpdateSidebar = await import('~/issuable');
        bulkUpdateSidebar.initBulkUpdateSidebar('issuable_');

        this.hasInitBulkEdit = true;
      }

      issuableEventHub.$emit('issuables:enableBulkEdit');
    },
    handleUpdateLegacyBulkEdit() {
      // If "select all" checkbox was checked, wait for all checkboxes
      // to be checked before updating IssuableBulkUpdateSidebar class
      this.$nextTick(() => {
        issuableEventHub.$emit('issuables:updateBulkEdit');
      });
    },
    targetBranchTooltip(mergeRequest) {
      return sprintf(__('Target branch: %{target_branch}'), {
        target_branch: mergeRequest.targetBranch,
      });
    },
  },
  STATUS_OPEN,
};
</script>

<template>
  <div>
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
      issuable-symbol="!"
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
      issuable-item-class="merge-request"
      :show-bulk-edit-sidebar="showBulkEditSidebar"
      @click-tab="handleClickTab"
      @next-page="handleNextPage"
      @previous-page="handlePreviousPage"
      @sort="handleSort"
      @filter="handleFilter"
      @update-legacy-bulk-edit="handleUpdateLegacyBulkEdit"
    >
      <template #nav-actions>
        <div class="gl-flex gl-gap-3">
          <gl-button
            v-if="mergeTrainsPath"
            :href="mergeTrainsPath"
            data-testid="merge-trains"
            variant="link"
            class="gl-mr-3"
          >
            {{ __('Merge trains') }}
          </gl-button>
          <gl-button
            v-if="canBulkUpdate"
            class="gl-grow"
            :disabled="isBulkEditButtonDisabled"
            data-testid="bulk-edit"
            @click="handleBulkUpdateClick"
          >
            {{ __('Bulk edit') }}
          </gl-button>

          <gl-button
            v-if="newMergeRequestPath"
            variant="confirm"
            :href="newMergeRequestPath"
            data-testid="new-merge-request-button"
            data-event-tracking="click_new_merge_request_list"
          >
            {{ $options.i18n.newMergeRequest }}
          </gl-button>

          <new-resource-dropdown
            v-if="showNewResourceDropdown"
            resource-type="merge-request"
            :group-id="groupId"
            :query-variables="resourceDropdownQueryVariables"
            with-local-storage
          />

          <merge-request-more-actions-dropdown :count="currentTabCount" />
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
          <gl-icon name="warning-solid" variant="strong" />
        </gl-link>
      </template>

      <template #timeframe="{ issuable = {} }">
        <issuable-milestone v-if="issuable.milestone" :milestone="issuable.milestone" />
      </template>

      <template #target-branch="{ issuable = {} }">
        <span
          v-if="defaultBranch && issuable.targetBranch !== defaultBranch"
          class="project-ref-path gl-inline-block gl-max-w-26 gl-truncate gl-align-bottom"
          data-testid="target-branch"
        >
          <gl-link
            v-gl-tooltip
            :href="issuable.targetBranchPath"
            :title="targetBranchTooltip(issuable)"
            class="ref-name !gl-text-subtle"
          >
            <gl-icon name="branch" :size="12" class="gl-mr-2" />{{ issuable.targetBranch }}
          </gl-link>
        </span>
      </template>

      <template #discussions="{ issuable = {} }">
        <li v-if="issuable.resolvableDiscussionsCount" class="!gl-mr-0 gl-hidden sm:gl-inline-flex">
          <discussions-badge :merge-request="issuable" />
        </li>
      </template>

      <template #statistics="{ issuable = {} }">
        <li
          v-if="issuable.upvotes || issuable.downvotes"
          class="!gl-mr-0 gl-hidden sm:gl-inline-flex"
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
          class="issuable-pipeline-status !gl-mr-0 gl-hidden sm:gl-flex"
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
        <empty-state :has-search="hasSearch" :is-open-tab="isOpenTab" />
      </template>
    </issuable-list>
    <empty-state v-else :has-merge-requests="false" />
    <issuable-by-email
      v-if="initialEmail"
      class="gl-pb-7 gl-pt-5 gl-text-center"
      data-track-action="click_email_issue_project_issues_empty_merge_request_page"
      data-track-label="email_issue_project_merge_request_empty_list"
    />
  </div>
</template>
