<script>
import { GlButton, GlEmptyState, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import getIssuesQuery from 'ee_else_ce/issues/dashboard/queries/get_issues.query.graphql';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import { IssuableStatus } from '~/issues/constants';
import {
  CREATED_DESC,
  i18n,
  PAGE_SIZE,
  PARAM_STATE,
  UPDATED_DESC,
  urlSortParams,
} from '~/issues/list/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  getFilterTokens,
  getInitialPageParams,
  getSortKey,
  getSortOptions,
  isSortKey,
} from '~/issues/list/utils';
import axios from '~/lib/utils/axios_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/vue_shared/issuable/list/constants';
import getIssuesCountsQuery from '../queries/get_issues_counts.query.graphql';
import { AutocompleteCache } from '../utils';

const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');
const EmojiToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue');
const LabelToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue');
const MilestoneToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue');

export default {
  i18n,
  IssuableListTabs,
  components: {
    GlButton,
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
    'calendarPath',
    'dashboardLabelsPath',
    'dashboardMilestonesPath',
    'emptyStateWithFilterSvgPath',
    'emptyStateWithoutFilterSvgPath',
    'hasBlockedIssuesFeature',
    'hasIssuableHealthStatusFeature',
    'hasIssueWeightsFeature',
    'hasScopedLabelsFeature',
    'initialSort',
    'isPublicVisibilityRestricted',
    'isSignedIn',
    'rssPath',
  ],
  data() {
    const state = getParameterByName(PARAM_STATE);

    const defaultSortKey = state === IssuableStates.Closed ? UPDATED_DESC : CREATED_DESC;
    const dashboardSortKey = getSortKey(this.initialSort);
    const graphQLSortKey =
      isSortKey(this.initialSort?.toUpperCase()) && this.initialSort.toUpperCase();

    // The initial sort is an old enum value when it is saved on the dashboard issues page.
    // The initial sort is a GraphQL enum value when it is saved on the Vue issues list page.
    const sortKey = dashboardSortKey || graphQLSortKey || defaultSortKey;

    return {
      filterTokens: getFilterTokens(window.location.search),
      issues: [],
      issuesCounts: {},
      issuesError: null,
      pageInfo: {},
      pageParams: getInitialPageParams(),
      sortKey,
      state: state || IssuableStates.Opened,
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
      debounce: 200,
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
      debounce: 200,
      context: {
        isSingleRequest: true,
      },
    },
  },
  computed: {
    apiFilterParams() {
      return convertToApiParams(this.filterTokens);
    },
    emptyStateDescription() {
      return this.hasSearch ? this.$options.i18n.noSearchResultsDescription : undefined;
    },
    emptyStateSvgPath() {
      return this.hasSearch
        ? this.emptyStateWithFilterSvgPath
        : this.emptyStateWithoutFilterSvgPath;
    },
    emptyStateTitle() {
      return this.hasSearch
        ? this.$options.i18n.noSearchResultsTitle
        : this.$options.i18n.noSearchNoFilterTitle;
    },
    hasSearch() {
      return Boolean(this.searchQuery || Object.keys(this.urlFilterParams).length);
    },
    queryVariables() {
      return {
        hideUsers: this.isPublicVisibilityRestricted && !this.isSignedIn,
        isSignedIn: this.isSignedIn,
        search: this.searchQuery,
        sort: this.sortKey,
        state: this.state,
        ...this.pageParams,
        ...this.apiFilterParams,
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
          fetchUsers: this.fetchUsers,
          preloadedUsers,
          recentSuggestionsStorageKey: 'dashboard-issues-recent-tokens-assignee',
        },
        {
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: UserToken,
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
          fetchLabels: this.fetchLabels,
          recentSuggestionsStorageKey: 'dashboard-issues-recent-tokens-label',
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'clock',
          token: MilestoneToken,
          fetchMilestones: this.fetchMilestones,
          recentSuggestionsStorageKey: 'dashboard-issues-recent-tokens-milestone',
          shouldSkipSort: true,
        },
      ];

      if (this.isSignedIn) {
        tokens.push({
          type: TOKEN_TYPE_MY_REACTION,
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          unique: true,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: 'dashboard-issues-recent-tokens-my_reaction',
        });
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
      });
    },
    tabCounts() {
      const { openedIssues, closedIssues, allIssues } = this.issuesCounts;
      return {
        [IssuableStates.Opened]: openedIssues?.count,
        [IssuableStates.Closed]: closedIssues?.count,
        [IssuableStates.All]: allIssues?.count,
      };
    },
    urlFilterParams() {
      return convertToUrlParams(this.filterTokens);
    },
    urlParams() {
      return {
        search: this.searchQuery,
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
      return axios.get('/-/autocomplete/users.json', { params: { active: true, search } });
    },
    getStatus(issue) {
      if (issue.state === IssuableStatus.Closed && issue.moved) {
        return this.$options.i18n.closedMoved;
      }
      if (issue.state === IssuableStatus.Closed) {
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
        firstPageSize: PAGE_SIZE,
      };
      scrollUp();
    },
    handlePreviousPage() {
      this.pageParams = {
        beforeCursor: this.pageInfo.startCursor,
        lastPageSize: PAGE_SIZE,
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
    :issuables-loading="$apollo.queries.issues.loading"
    namespace="dashboard"
    recent-searches-storage-key="issues"
    :search-input-placeholder="$options.i18n.searchPlaceholder"
    :search-tokens="searchTokens"
    :show-pagination-controls="showPaginationControls"
    show-work-item-type-icon
    :sort-options="sortOptions"
    :tab-counts="tabCounts"
    :tabs="$options.IssuableListTabs"
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
      <gl-button :href="rssPath" icon="rss">
        {{ $options.i18n.rssLabel }}
      </gl-button>
      <gl-button :href="calendarPath" icon="calendar">
        {{ $options.i18n.calendarLabel }}
      </gl-button>
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
