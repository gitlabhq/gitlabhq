<script>
import {
  GlDisclosureDropdown,
  GlEmptyState,
  GlFilteredSearchToken,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import getIssuesQuery from 'ee_else_ce/issues/dashboard/queries/get_issues.query.graphql';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import {
  CREATED_DESC,
  defaultTypeTokenOptions,
  i18n,
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
  OPERATORS_IS,
  OPERATORS_IS_NOT_OR,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_SEARCH_WITHIN,
  TOKEN_TITLE_TYPE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_TYPE,
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

    const defaultSortKey = state === STATUS_CLOSED ? UPDATED_DESC : CREATED_DESC;
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
      context: {
        isSingleRequest: true,
      },
    },
  },
  computed: {
    apiFilterParams() {
      return convertToApiParams(this.filterTokens);
    },
    dropdownItems() {
      return [
        { href: this.rssPath, text: i18n.rssLabel },
        { href: this.calendarPath, text: i18n.calendarLabel },
      ];
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
          icon: 'clock',
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
          options: defaultTypeTokenOptions,
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
        [STATUS_OPEN]: openedIssues?.count,
        [STATUS_CLOSED]: closedIssues?.count,
        [STATUS_ALL]: allIssues?.count,
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
    :issuables-loading="$apollo.queries.issues.loading"
    namespace="dashboard"
    recent-searches-storage-key="issues"
    :search-input-placeholder="$options.i18n.searchPlaceholder"
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
