<script>
import {
  GlDisclosureDropdown,
  GlEmptyState,
  GlFilteredSearchToken,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import getIssuesQuery from 'ee_else_ce/issues/dashboard/queries/get_issues.query.graphql';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  deriveSortKey,
  getDefaultWorkItemTypes,
  getFilterTokens,
  getInitialPageParams,
  getSortOptions,
  getTypeTokenOptions,
} from 'ee_else_ce/issues/list/utils';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import { i18n, PARAM_STATE, urlSortParams } from '~/issues/list/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { fetchPolicies } from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  OPERATORS_IS,
  OPERATORS_IS_NOT_OR,
  OPERATORS_AFTER_BEFORE,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_SEARCH_WITHIN,
  TOKEN_TITLE_TYPE,
  TOKEN_TITLE_CREATED,
  TOKEN_TITLE_CLOSED,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_CREATED,
  TOKEN_TYPE_CLOSED,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { DEFAULT_PAGE_SIZE, issuableListTabs } from '~/vue_shared/issuable/list/constants';
import getIssuesCountsQuery from '../queries/get_issues_counts.query.graphql';
import { AutocompleteCache } from '../utils';

const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');
const EmojiToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue');
const LabelToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue');
const DateToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/date_token.vue');
const MilestoneToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue');

export default {
  i18n,
  issuableListTabs,
  components: {
    GlDisclosureDropdown,
    GlEmptyState,
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'autocompleteAwardEmojisPath',
    'autocompleteUsersPath',
    'calendarPath',
    'dashboardLabelsPath',
    'dashboardMilestonesPath',
    'emptyStateWithFilterSvgPath',
    'emptyStateWithoutFilterSvgPath',
    'hasBlockedIssuesFeature',
    'hasIssuableHealthStatusFeature',
    'hasIssueDateFilterFeature',
    'hasIssueWeightsFeature',
    'hasOkrsFeature',
    'hasQualityManagementFeature',
    'hasScopedLabelsFeature',
    'initialSort',
    'isPublicVisibilityRestricted',
    'isSignedIn',
    'rssPath',
  ],
  data() {
    const state = getParameterByName(PARAM_STATE);

    return {
      filterTokens: getFilterTokens(window.location.search),
      issues: [],
      issuesCounts: {},
      issuesError: null,
      pageInfo: {},
      pageParams: getInitialPageParams(),
      sortKey: deriveSortKey({ sort: this.initialSort, state }),
      state: state || STATUS_OPEN,
    };
  },
  apollo: {
    issues: {
      query: getIssuesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.issues.nodes ?? [];
      },
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      // We need this for handling loading state when using frontend cache
      // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106004#note_1217325202 for details
      notifyOnNetworkStatusChange: true,
      result({ data }) {
        this.pageInfo = data?.issues.pageInfo ?? {};
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingIssues;
        Sentry.captureException(error);
      },
      skip() {
        return !this.hasSearch;
      },
    },
    issuesCounts: {
      query: getIssuesCountsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data ?? {};
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingCounts;
        Sentry.captureException(error);
      },
      skip() {
        return !this.hasSearch;
      },
    },
  },
  computed: {
    apiFilterParams() {
      return convertToApiParams(this.filterTokens);
    },
    defaultWorkItemTypes() {
      return getDefaultWorkItemTypes({
        hasOkrsFeature: this.hasOkrsFeature,
        hasQualityManagementFeature: this.hasQualityManagementFeature,
      });
    },
    dropdownItems() {
      return [
        { href: this.rssPath, text: __('Subscribe to RSS feed') },
        { href: this.calendarPath, text: __('Subscribe to calendar') },
      ];
    },
    emptyStateDescription() {
      return this.hasSearch
        ? __('To widen your search, change or remove filters above')
        : undefined;
    },
    emptyStateSvgPath() {
      return this.hasSearch
        ? this.emptyStateWithFilterSvgPath
        : this.emptyStateWithoutFilterSvgPath;
    },
    emptyStateTitle() {
      return this.hasSearch
        ? __('Sorry, your filter produced no results')
        : __('Please select at least one filter to see results');
    },
    hasSearch() {
      return Boolean(this.searchQuery || Object.keys(this.urlFilterParams).length);
    },
    // due to the issues with cache-and-network, we need this hack to check if there is any data for the query in the cache.
    // if we have cached data, we disregard the loading state
    isLoading() {
      return (
        this.$apollo.queries.issues.loading &&
        !this.$apollo.provider.clients.defaultClient.readQuery({
          query: getIssuesQuery,
          variables: this.queryVariables,
        })
      );
    },
    queryVariables() {
      return {
        hideUsers: this.isPublicVisibilityRestricted && !this.isSignedIn,
        isSignedIn: this.isSignedIn,
        sort: this.sortKey,
        state: this.state,
        ...this.pageParams,
        ...this.apiFilterParams,
        types: this.apiFilterParams.types || this.defaultWorkItemTypes,
      };
    },
    renderedIssues() {
      return this.hasSearch ? this.issues : [];
    },
    searchQuery() {
      return convertToSearchQuery(this.filterTokens);
    },
    searchTokens() {
      const preloadedUsers = [];

      if (gon.current_user_id) {
        preloadedUsers.push({
          id: gon.current_user_id,
          name: gon.current_user_fullname,
          username: gon.current_username,
          avatar_url: gon.current_user_avatar_url,
        });
      }

      const tokens = [
        {
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT_OR,
          fetchUsers: this.fetchUsers,
          preloadedUsers,
          recentSuggestionsStorageKey: 'dashboard-issues-recent-tokens-assignee',
        },
        {
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT_OR,
          fetchUsers: this.fetchUsers,
          defaultUsers: [],
          preloadedUsers,
          recentSuggestionsStorageKey: 'dashboard-issues-recent-tokens-author',
        },
        {
          type: TOKEN_TYPE_LABEL,
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
          operators: OPERATORS_IS_NOT_OR,
          fetchLabels: this.fetchLabels,
          recentSuggestionsStorageKey: 'dashboard-issues-recent-tokens-label',
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          token: MilestoneToken,
          fetchMilestones: this.fetchMilestones,
          recentSuggestionsStorageKey: 'dashboard-issues-recent-tokens-milestone',
          shouldSkipSort: true,
        },
        {
          type: TOKEN_TYPE_SEARCH_WITHIN,
          title: TOKEN_TITLE_SEARCH_WITHIN,
          icon: 'search',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            { icon: 'title', value: 'TITLE', title: this.$options.i18n.titles },
            {
              icon: 'text-description',
              value: 'DESCRIPTION',
              title: this.$options.i18n.descriptions,
            },
          ],
        },
        {
          type: TOKEN_TYPE_TYPE,
          title: TOKEN_TITLE_TYPE,
          icon: 'issues',
          token: GlFilteredSearchToken,
          options: this.typeTokenOptions,
        },
      ];

      if (this.isSignedIn) {
        tokens.push({
          type: TOKEN_TYPE_CONFIDENTIAL,
          title: TOKEN_TITLE_CONFIDENTIAL,
          icon: 'eye-slash',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            { icon: 'eye-slash', value: 'yes', title: this.$options.i18n.confidentialYes },
            { icon: 'eye', value: 'no', title: this.$options.i18n.confidentialNo },
          ],
        });

        tokens.push({
          type: TOKEN_TYPE_MY_REACTION,
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          unique: true,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: 'dashboard-issues-recent-tokens-my_reaction',
        });

        if (this.hasIssueDateFilterFeature) {
          tokens.push({
            type: TOKEN_TYPE_CREATED,
            title: TOKEN_TITLE_CREATED,
            icon: 'history',
            token: DateToken,
            operators: OPERATORS_AFTER_BEFORE,
          });

          tokens.push({
            type: TOKEN_TYPE_CLOSED,
            title: TOKEN_TITLE_CLOSED,
            icon: 'history',
            token: DateToken,
            operators: OPERATORS_AFTER_BEFORE,
          });
        }
      }

      tokens.sort((a, b) => a.title.localeCompare(b.title));

      return tokens;
    },
    showPaginationControls() {
      return (
        this.renderedIssues.length > 0 &&
        (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage)
      );
    },
    sortOptions() {
      return getSortOptions({
        hasBlockedIssuesFeature: this.hasBlockedIssuesFeature,
        hasIssuableHealthStatusFeature: this.hasIssuableHealthStatusFeature,
        hasIssueWeightsFeature: this.hasIssueWeightsFeature,
        hasManualSort: false,
      });
    },
    tabCounts() {
      const { openedIssues, closedIssues, allIssues } = this.issuesCounts;
      return {
        [STATUS_OPEN]: openedIssues?.count,
        [STATUS_CLOSED]: closedIssues?.count,
        [STATUS_ALL]: allIssues?.count,
      };
    },
    typeTokenOptions() {
      return getTypeTokenOptions({
        hasOkrsFeature: this.hasOkrsFeature,
        hasQualityManagementFeature: this.hasQualityManagementFeature,
      });
    },
    urlFilterParams() {
      return convertToUrlParams(this.filterTokens);
    },
    urlParams() {
      return {
        sort: urlSortParams[this.sortKey],
        state: this.state,
        ...this.urlFilterParams,
      };
    },
  },
  created() {
    this.autocompleteCache = new AutocompleteCache();
  },
  methods: {
    fetchEmojis(search) {
      return this.autocompleteCache.fetch({
        url: this.autocompleteAwardEmojisPath,
        cacheName: 'emojis',
        searchProperty: 'name',
        search,
      });
    },
    fetchLabels(search) {
      return this.autocompleteCache.fetch({
        url: this.dashboardLabelsPath,
        cacheName: 'labels',
        searchProperty: 'title',
        search,
      });
    },
    fetchMilestones(search) {
      return this.autocompleteCache.fetch({
        url: this.dashboardMilestonesPath,
        cacheName: 'milestones',
        searchProperty: 'title',
        search,
      });
    },
    fetchUsers(search) {
      return axios.get(this.autocompleteUsersPath, {
        params: { active: true, search },
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
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }
      this.state = state;
      this.pageParams = getInitialPageParams();
    },
    handleDismissAlert() {
      this.issuesError = null;
    },
    handleFilter(tokens) {
      this.filterTokens = tokens;
      this.pageParams = getInitialPageParams();
    },
    handleNextPage() {
      this.pageParams = {
        afterCursor: this.pageInfo.endCursor,
        firstPageSize: DEFAULT_PAGE_SIZE,
      };
      scrollUp();
    },
    handlePreviousPage() {
      this.pageParams = {
        beforeCursor: this.pageInfo.startCursor,
        lastPageSize: DEFAULT_PAGE_SIZE,
      };
      scrollUp();
    },
    handleSort(sortKey) {
      if (this.sortKey === sortKey) {
        return;
      }

      this.sortKey = sortKey;
      this.pageParams = getInitialPageParams();

      if (this.isSignedIn) {
        this.saveSortPreference(sortKey);
      }
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
  },
};
</script>

<template>
  <issuable-list
    :current-tab="state"
    :error="issuesError"
    :has-next-page="pageInfo.hasNextPage"
    :has-previous-page="pageInfo.hasPreviousPage"
    :has-scoped-labels-feature="hasScopedLabelsFeature"
    :initial-filter-value="filterTokens"
    :initial-sort-by="sortKey"
    :issuables="renderedIssues"
    :issuables-loading="isLoading"
    namespace="dashboard"
    recent-searches-storage-key="issues"
    :search-tokens="searchTokens"
    :show-pagination-controls="showPaginationControls"
    show-work-item-type-icon
    :sort-options="sortOptions"
    :tab-counts="tabCounts"
    :tabs="$options.issuableListTabs"
    truncate-counts
    :url-params="urlParams"
    use-keyset-pagination
    @click-tab="handleClickTab"
    @dismiss-alert="handleDismissAlert"
    @filter="handleFilter"
    @next-page="handleNextPage"
    @previous-page="handlePreviousPage"
    @sort="handleSort"
  >
    <template #nav-actions>
      <gl-disclosure-dropdown
        v-gl-tooltip="$options.i18n.actionsLabel"
        category="tertiary"
        icon="ellipsis_v"
        :items="dropdownItems"
        no-caret
        text-sr-only
        :toggle-text="$options.i18n.actionsLabel"
      />
    </template>

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
      <gl-empty-state
        :description="emptyStateDescription"
        :svg-path="emptyStateSvgPath"
        :title="emptyStateTitle"
      />
    </template>
  </issuable-list>
</template>
