<script>
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { isEmpty } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { fetchPolicies } from '~/lib/graphql';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import axios from '~/lib/utils/axios_utils';
import { getParameterByName, joinPaths } from '~/lib/utils/url_utility';
import { scrollUp } from '~/lib/utils/scroll_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';

import { DEFAULT_PAGE_SIZE, issuableListTabs } from '~/vue_shared/issuable/list/constants';
import {
  convertToSearchQuery,
  convertToApiParams,
  deriveSortKey,
  getInitialPageParams,
  getFilterTokens,
  getSortOptions,
} from '~/issues/list/utils';
import { OPERATORS_IS_NOT_OR } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  CLOSED_MOVED,
  CLOSED,
  CREATED_DESC,
  ISSUE_REFERENCE,
  MAX_LIST_SIZE,
  PARAM_FIRST_PAGE_SIZE,
  PARAM_LAST_PAGE_SIZE,
  PARAM_PAGE_AFTER,
  PARAM_PAGE_BEFORE,
  PARAM_SORT,
  PARAM_STATE,
  RELATIVE_POSITION_ASC,
  UPDATED_DESC,
  urlSortParams,
} from '~/issues/list/constants';
import { createAlert, VARIANT_INFO } from '~/alert';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import searchProjectMembers from '~/graphql_shared/queries/project_user_members_search.query.graphql';
import getServiceDeskIssuesQuery from 'ee_else_ce/issues/service_desk/queries/get_service_desk_issues.query.graphql';
import getServiceDeskIssuesCounts from 'ee_else_ce/issues/service_desk/queries/get_service_desk_issues_counts.query.graphql';
import searchProjectLabelsQuery from '../queries/search_project_labels.query.graphql';
import searchProjectMilestonesQuery from '../queries/search_project_milestones.query.graphql';
import setSortingPreferenceMutation from '../queries/set_sorting_preference.mutation.graphql';
import reorderServiceDeskIssuesMutation from '../queries/reorder_service_desk_issues.mutation.graphql';
import {
  errorFetchingCounts,
  errorFetchingIssues,
  issueRepositioningMessage,
  reorderError,
  SERVICE_DESK_BOT_USERNAME,
  STATUS_OPEN,
  STATUS_CLOSED,
  STATUS_ALL,
  WORKSPACE_PROJECT,
} from '../constants';
import { convertToUrlParams } from '../utils';
import {
  searchWithinTokenBase,
  assigneeTokenBase,
  milestoneTokenBase,
  labelTokenBase,
  releaseTokenBase,
  reactionTokenBase,
  confidentialityTokenBase,
} from '../search_tokens';
import InfoBanner from './info_banner.vue';
import EmptyStateWithAnyIssues from './empty_state_with_any_issues.vue';
import EmptyStateWithoutAnyIssues from './empty_state_without_any_issues.vue';

export default {
  i18n: {
    errorFetchingCounts,
    errorFetchingIssues,
    issueRepositioningMessage,
    reorderError,
    closed: CLOSED,
    closedMoved: CLOSED_MOVED,
  },
  issuableListTabs,
  components: {
    IssuableList,
    InfoBanner,
    IssueCardTimeInfo,
    IssueCardStatistics,
    EmptyStateWithAnyIssues,
    EmptyStateWithoutAnyIssues,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'releasesPath',
    'autocompleteAwardEmojisPath',
    'hasBlockedIssuesFeature',
    'hasIterationsFeature',
    'hasIssueWeightsFeature',
    'hasIssuableHealthStatusFeature',
    'groupPath',
    'emptyStateSvgPath',
    'isProject',
    'isSignedIn',
    'fullPath',
    'isServiceDeskSupported',
    'hasAnyIssues',
    'initialSort',
    'isIssueRepositioningDisabled',
  ],
  props: {
    eeSearchTokens: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      serviceDeskIssues: [],
      serviceDeskIssuesCounts: {},
      filterTokens: [],
      pageInfo: {},
      pageParams: {},
      sortKey: CREATED_DESC,
      state: STATUS_OPEN,
      pageSize: DEFAULT_PAGE_SIZE,
      issuesError: '',
    };
  },
  apollo: {
    serviceDeskIssues: {
      query: getServiceDeskIssuesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.project.issues.nodes ?? [];
      },
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      // We need this for handling loading state when using frontend cache
      // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106004#note_1217325202 for details
      notifyOnNetworkStatusChange: true,
      result({ data }) {
        if (!data) {
          return;
        }
        this.pageInfo = data?.project.issues.pageInfo ?? {};
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingIssues;
        Sentry.captureException(error);
      },
      skip() {
        return this.shouldSkipQuery;
      },
    },
    serviceDeskIssuesCounts: {
      query: getServiceDeskIssuesCounts,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.project ?? {};
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingCounts;
        Sentry.captureException(error);
      },
      skip() {
        return this.shouldSkipQuery;
      },
    },
  },
  computed: {
    queryVariables() {
      const isIidSearch = ISSUE_REFERENCE.test(this.searchQuery);
      return {
        fullPath: this.fullPath,
        iid: isIidSearch ? this.searchQuery.slice(1) : undefined,
        isSignedIn: this.isSignedIn,
        authorUsername: SERVICE_DESK_BOT_USERNAME,
        sort: this.sortKey,
        state: this.state,
        ...this.pageParams,
        ...this.apiFilterParams,
        search: isIidSearch ? undefined : this.searchQuery,
      };
    },
    shouldSkipQuery() {
      return !this.hasAnyIssues || isEmpty(this.pageParams);
    },
    sortOptions() {
      return getSortOptions({
        hasBlockedIssuesFeature: this.hasBlockedIssuesFeature,
        hasIssuableHealthStatusFeature: this.hasIssuableHealthStatusFeature,
        hasIssueWeightsFeature: this.hasIssueWeightsFeature,
      });
    },
    tabCounts() {
      const { openedIssues, closedIssues, allIssues } = this.serviceDeskIssuesCounts;
      return {
        [STATUS_OPEN]: openedIssues?.count,
        [STATUS_CLOSED]: closedIssues?.count,
        [STATUS_ALL]: allIssues?.count,
      };
    },
    showPaginationControls() {
      return !this.isLoading && (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage);
    },
    showPageSizeSelector() {
      return this.serviceDeskIssues.length > 0;
    },
    isLoading() {
      return this.$apollo.loading;
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
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
    hasAnyServiceDeskIssue() {
      return this.hasSearch || Boolean(this.tabCounts.all);
    },
    isInfoBannerVisible() {
      return this.isServiceDeskSupported && this.hasAnyServiceDeskIssue;
    },
    canShowIssuesList() {
      return this.isLoading || this.issuesError.length || this.hasAnyServiceDeskIssue;
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

      if (gon.current_user_id) {
        preloadedUsers.push({
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          name: gon.current_user_fullname,
          username: gon.current_username,
          avatar_url: gon.current_user_avatar_url,
        });
      }

      const tokens = [
        {
          ...searchWithinTokenBase,
        },
        {
          ...assigneeTokenBase,
          operators: OPERATORS_IS_NOT_OR,
          fetchUsers: this.fetchUsers,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-assignee`,
          preloadedUsers,
        },
        {
          ...milestoneTokenBase,
          fetchMilestones: this.fetchMilestones,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-milestone`,
        },
        {
          ...labelTokenBase,
          operators: OPERATORS_IS_NOT_OR,
          fetchLabels: this.fetchLabels,
          fetchLatestLabels: this.glFeatures.frontendCaching ? this.fetchLatestLabels : null,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-label`,
        },
      ];

      if (this.isProject) {
        tokens.push({
          ...releaseTokenBase,
          fetchReleases: this.fetchReleases,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-release`,
        });
      }

      if (this.isSignedIn) {
        tokens.push({
          ...reactionTokenBase,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-my_reaction`,
        });

        tokens.push({
          ...confidentialityTokenBase,
        });
      }

      if (this.eeSearchTokens.length) {
        tokens.push(...this.eeSearchTokens);
      }

      tokens.sort((a, b) => a.title.localeCompare(b.title));

      return tokens;
    },
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION_ASC;
    },
  },
  watch: {
    $route(newValue, oldValue) {
      if (newValue.fullPath !== oldValue.fullPath) {
        this.updateData(getParameterByName(PARAM_SORT));
      }
    },
  },
  created() {
    this.updateData(this.initialSort);
    this.cache = {};
  },
  methods: {
    // eslint-disable-next-line max-params
    fetchWithCache(path, cacheName, searchKey, search) {
      if (this.cache[cacheName]) {
        const data = search
          ? fuzzaldrinPlus.filter(this.cache[cacheName], search, { key: searchKey })
          : this.cache[cacheName].slice(0, MAX_LIST_SIZE);
        return Promise.resolve(data);
      }

      return axios.get(path).then(({ data }) => {
        this.cache[cacheName] = data;
        return data.slice(0, MAX_LIST_SIZE);
      });
    },
    fetchUsers(search) {
      return this.$apollo
        .query({
          query: searchProjectMembers,
          variables: { fullPath: this.fullPath, search },
        })
        .then(({ data }) =>
          data[WORKSPACE_PROJECT]?.[`${WORKSPACE_PROJECT}Members`].nodes.map(
            (member) => member.user,
          ),
        );
    },
    fetchMilestones(search) {
      return this.$apollo
        .query({
          query: searchProjectMilestonesQuery,
          variables: { fullPath: this.fullPath, search },
        })
        .then(({ data }) => data[WORKSPACE_PROJECT]?.milestones.nodes);
    },
    fetchEmojis(search) {
      return this.fetchWithCache(this.autocompleteAwardEmojisPath, 'emojis', 'name', search);
    },
    fetchReleases(search) {
      return this.fetchWithCache(this.releasesPath, 'releases', 'tag', search);
    },
    fetchLabelsWithFetchPolicy(search, fetchPolicy = fetchPolicies.CACHE_FIRST) {
      return this.$apollo
        .query({
          query: searchProjectLabelsQuery,
          variables: { fullPath: this.fullPath, search },
          fetchPolicy,
        })
        .then(({ data }) => data[WORKSPACE_PROJECT]?.labels.nodes)
        .then((labels) =>
          // TODO remove once we can search by title-only on the backend
          // https://gitlab.com/gitlab-org/gitlab/-/issues/346353
          labels.filter((label) => label.title.toLowerCase().includes(search.toLowerCase())),
        );
    },
    fetchLabels(search) {
      return this.fetchLabelsWithFetchPolicy(search);
    },
    fetchLatestLabels(search) {
      return this.fetchLabelsWithFetchPolicy(search, fetchPolicies.NETWORK_ONLY);
    },
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }
      this.state = state;
      this.pageParams = getInitialPageParams(this.pageSize);

      this.$router.push({ query: this.urlParams });
    },
    handleFilter(tokens) {
      this.filterTokens = tokens;
      this.pageParams = getInitialPageParams(this.pageSize);

      this.$router.push({ query: this.urlParams });
    },
    handleDismissAlert() {
      this.issuesError = '';
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
    handlePageSizeChange(pageSize) {
      this.pageSize = pageSize;
      this.pageParams = getInitialPageParams(pageSize);
      scrollUp();

      this.$router.push({ query: this.urlParams });
    },
    handleSort(sortKey) {
      if (this.sortKey === sortKey) {
        return;
      }

      if (this.isIssueRepositioningDisabled && sortKey === RELATIVE_POSITION_ASC) {
        this.showIssueRepositioningMessage();
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
          mutation: setSortingPreferenceMutation,
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
    handleReorder({ newIndex, oldIndex }) {
      const issueToMove = this.serviceDeskIssues[oldIndex];
      const isDragDropDownwards = newIndex > oldIndex;
      const isMovingToBeginning = newIndex === 0;
      const isMovingToEnd = newIndex === this.serviceDeskIssues.length - 1;

      let moveBeforeId;
      let moveAfterId;

      if (isDragDropDownwards) {
        const afterIndex = isMovingToEnd ? newIndex : newIndex + 1;
        moveBeforeId = this.serviceDeskIssues[newIndex].id;
        moveAfterId = this.serviceDeskIssues[afterIndex].id;
      } else {
        const beforeIndex = isMovingToBeginning ? newIndex : newIndex - 1;
        moveBeforeId = this.serviceDeskIssues[beforeIndex].id;
        moveAfterId = this.serviceDeskIssues[newIndex].id;
      }

      return axios
        .put(joinPaths(issueToMove.webPath, 'reorder'), {
          move_before_id: isMovingToBeginning ? null : getIdFromGraphQLId(moveBeforeId),
          move_after_id: isMovingToEnd ? null : getIdFromGraphQLId(moveAfterId),
        })
        .then(() => {
          const serializedVariables = JSON.stringify(this.queryVariables);
          return this.$apollo.mutate({
            mutation: reorderServiceDeskIssuesMutation,
            variables: { oldIndex, newIndex, namespace: this.namespace, serializedVariables },
          });
        })
        .catch((error) => {
          this.issuesError = this.$options.i18n.reorderError;
          Sentry.captureException(error);
        });
    },
    updateData(sort) {
      const firstPageSize = getParameterByName(PARAM_FIRST_PAGE_SIZE);
      const lastPageSize = getParameterByName(PARAM_LAST_PAGE_SIZE);
      const state = getParameterByName(PARAM_STATE);

      let sortKey = deriveSortKey({ sort, state });

      if (this.isIssueRepositioningDisabled && sortKey === RELATIVE_POSITION_ASC) {
        this.showIssueRepositioningMessage();
        sortKey = state === STATUS_CLOSED ? UPDATED_DESC : CREATED_DESC;
      }

      this.filterTokens = getFilterTokens(window.location.search);

      this.pageParams = getInitialPageParams(
        this.pageSize,
        isPositiveInteger(firstPageSize) ? parseInt(firstPageSize, 10) : undefined,
        isPositiveInteger(lastPageSize) ? parseInt(lastPageSize, 10) : undefined,
        getParameterByName(PARAM_PAGE_AFTER),
        getParameterByName(PARAM_PAGE_BEFORE),
      );
      this.sortKey = sortKey;
      this.state = state || STATUS_OPEN;
    },
    showIssueRepositioningMessage() {
      createAlert({
        message: this.$options.i18n.issueRepositioningMessage,
        variant: VARIANT_INFO,
      });
    },
    getStatus(issue) {
      if (issue.state === STATUS_CLOSED && issue.moved) {
        return this.$options.i18n.closedMoved;
      }
      if (issue.state === STATUS_CLOSED) {
        return this.$options.i18n.closed;
      }
      return undefined;
    },
  },
};
</script>

<template>
  <section>
    <info-banner v-if="isInfoBannerVisible" />
    <issuable-list
      v-if="canShowIssuesList"
      namespace="service-desk"
      recent-searches-storage-key="service-desk-issues"
      :error="issuesError"
      :search-tokens="searchTokens"
      :issuables-loading="isLoading"
      :initial-filter-value="filterTokens"
      :show-pagination-controls="showPaginationControls"
      :show-page-size-selector="showPageSizeSelector"
      :sort-options="sortOptions"
      :initial-sort-by="sortKey"
      :is-manual-ordering="isManualOrdering"
      :issuables="serviceDeskIssues"
      :tabs="$options.issuableListTabs"
      :tab-counts="tabCounts"
      :current-tab="state"
      :default-page-size="pageSize"
      :has-next-page="pageInfo.hasNextPage"
      :has-previous-page="pageInfo.hasPreviousPage"
      show-filtered-search-friendly-text
      sync-filter-and-sort
      use-keyset-pagination
      @click-tab="handleClickTab"
      @dismiss-alert="handleDismissAlert"
      @filter="handleFilter"
      @sort="handleSort"
      @reorder="handleReorder"
      @next-page="handleNextPage"
      @previous-page="handlePreviousPage"
      @page-size-change="handlePageSizeChange"
    >
      <template #timeframe="{ issuable = {} }">
        <issue-card-time-info :issue="issuable" />
      </template>

      <template #status="{ issuable = {} }">
        {{ getStatus(issuable) }}
      </template>

      <template #statistics="{ issuable = {} }">
        <issue-card-statistics :issue="issuable" />
      </template>

      <template #empty-state>
        <empty-state-with-any-issues :has-search="hasSearch" :is-open-tab="isOpenTab" />
      </template>
    </issuable-list>

    <empty-state-without-any-issues v-else />
  </section>
</template>
