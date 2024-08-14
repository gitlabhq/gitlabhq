<script>
import { GlFilteredSearchToken, GlLoadingIcon } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import {
  convertToApiParams,
  convertToSearchQuery,
  deriveSortKey,
  getDefaultWorkItemTypes,
  getInitialPageParams,
  getTypeTokenOptions,
} from 'ee_else_ce/issues/list/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  STATUS_ALL,
  STATUS_CLOSED,
  STATUS_OPEN,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import { AutocompleteCache } from '~/issues/dashboard/utils';
import searchLabelsQuery from '~/issues/list/queries/search_labels.query.graphql';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { fetchPolicies } from '~/lib/graphql';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { __, s__ } from '~/locale';
import {
  OPERATORS_IS,
  OPERATORS_IS_NOT_OR,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_GROUP,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_SEARCH_WITHIN,
  TOKEN_TITLE_TYPE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_GROUP,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_TYPE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { DEFAULT_PAGE_SIZE, issuableListTabs } from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { STATE_CLOSED, WORK_ITEM_TYPE_ENUM_EPIC } from '../constants';
import getWorkItemsQuery from '../graphql/list/get_work_items.query.graphql';
import { sortOptions, urlSortParams } from './list/constants';

const EmojiToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue');
const GroupToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/group_token.vue');
const LabelToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue');
const MilestoneToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue');
const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');

export default {
  issuableListTabs,
  sortOptions,
  components: {
    GlLoadingIcon,
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'autocompleteAwardEmojisPath',
    'fullPath',
    'hasEpicsFeature',
    'hasOkrsFeature',
    'hasQualityManagementFeature',
    'initialSort',
    'isGroup',
    'isSignedIn',
    'workItemType',
  ],
  props: {
    eeWorkItemUpdateCount: {
      type: Number,
      required: false,
      default: 0,
    },
    showBulkEditSidebar: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      error: undefined,
      filterTokens: [],
      hasAnyIssues: false,
      isInitialAllCountSet: false,
      pageInfo: {},
      pageParams: getInitialPageParams(),
      pageSize: DEFAULT_PAGE_SIZE,
      sortKey: deriveSortKey({ sort: this.initialSort, sortMap: urlSortParams }),
      state: STATUS_OPEN,
      tabCounts: {},
      workItems: [],
    };
  },
  apollo: {
    workItems: {
      query: getWorkItemsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          sort: this.sortKey,
          state: this.state,
          search: this.searchQuery,
          ...this.apiFilterParams,
          ...this.pageParams,
          includeDescendants: !this.apiFilterParams.fullPath,
          types: this.apiFilterParams.types || this.workItemType || this.defaultWorkItemTypes,
        };
      },
      update(data) {
        return data.group.workItems.nodes ?? [];
      },
      result({ data }) {
        const { all, closed, opened } = data?.group.workItemStateCounts ?? {};

        this.pageInfo = data?.group.workItems.pageInfo ?? {};
        this.tabCounts = {
          [STATUS_OPEN]: opened,
          [STATUS_CLOSED]: closed,
          [STATUS_ALL]: all,
        };

        if (!this.isInitialAllCountSet) {
          this.hasAnyIssues = Boolean(all);
          this.isInitialAllCountSet = true;
        }
        if (data?.group) {
          const rootBreadcrumbName =
            this.workItemType === WORK_ITEM_TYPE_ENUM_EPIC
              ? __('Epics')
              : s__('WorkItem|Work items');
          document.title = `${rootBreadcrumbName} · ${data.group.name} · GitLab`;
        }
      },
      error(error) {
        this.error = s__(
          'WorkItem|Something went wrong when fetching work items. Please try again.',
        );
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    apiFilterParams() {
      return convertToApiParams(this.filterTokens);
    },
    defaultWorkItemTypes() {
      return getDefaultWorkItemTypes({
        hasEpicsFeature: this.hasEpicsFeature,
        hasOkrsFeature: this.hasOkrsFeature,
        hasQualityManagementFeature: this.hasQualityManagementFeature,
      });
    },
    hasSearch() {
      return Boolean(this.searchQuery);
    },
    isLoading() {
      return this.$apollo.queries.workItems.loading;
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
    },
    namespace() {
      return this.isGroup ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
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
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT_OR,
          fullPath: this.fullPath,
          isProject: !this.isGroup,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-assignee`,
          preloadedUsers,
          multiSelect: this.glFeatures.groupMultiSelectTokens,
        },
        {
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: UserToken,
          dataType: 'user',
          defaultUsers: [],
          operators: OPERATORS_IS_NOT_OR,
          fullPath: this.fullPath,
          isProject: !this.isGroup,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-author`,
          preloadedUsers,
          multiSelect: this.glFeatures.groupMultiSelectTokens,
        },
        {
          type: TOKEN_TYPE_GROUP,
          icon: 'group',
          title: TOKEN_TITLE_GROUP,
          unique: true,
          token: GroupToken,
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
        },
        {
          type: TOKEN_TYPE_LABEL,
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
          operators: OPERATORS_IS_NOT_OR,
          fetchLabels: this.fetchLabels,
          fetchLatestLabels: this.glFeatures.frontendCaching ? this.fetchLatestLabels : null,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-label`,
          multiSelect: this.glFeatures.groupMultiSelectTokens,
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          token: MilestoneToken,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-milestone`,
          shouldSkipSort: true,
          fullPath: this.fullPath,
          isProject: !this.isGroup,
        },
        {
          type: TOKEN_TYPE_SEARCH_WITHIN,
          title: TOKEN_TITLE_SEARCH_WITHIN,
          icon: 'search',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            { icon: 'title', value: 'TITLE', title: __('Titles') },
            { icon: 'text-description', value: 'DESCRIPTION', title: __('Descriptions') },
          ],
        },
      ];

      if (!this.workItemType) {
        tokens.push({
          type: TOKEN_TYPE_TYPE,
          title: TOKEN_TITLE_TYPE,
          icon: 'issues',
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          options: this.typeTokenOptions,
        });
      }

      if (this.isSignedIn) {
        tokens.push({
          type: TOKEN_TYPE_CONFIDENTIAL,
          title: TOKEN_TITLE_CONFIDENTIAL,
          icon: 'eye-slash',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            { icon: 'eye-slash', value: 'yes', title: __('Yes') },
            { icon: 'eye', value: 'no', title: __('No') },
          ],
        });

        tokens.push({
          type: TOKEN_TYPE_MY_REACTION,
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          unique: true,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-my_reaction`,
        });
      }

      tokens.sort((a, b) => a.title.localeCompare(b.title));

      return tokens;
    },
    showPaginationControls() {
      return !this.isLoading && (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage);
    },
    showPageSizeSelector() {
      return this.workItems.length > 0;
    },
    typeTokenOptions() {
      return getTypeTokenOptions({
        hasEpicsFeature: this.hasEpicsFeature,
        hasOkrsFeature: this.hasOkrsFeature,
        hasQualityManagementFeature: this.hasQualityManagementFeature,
      });
    },
  },
  watch: {
    eeWorkItemUpdateCount() {
      // Only reset isInitialAllCountSet when there's no issues to minimize unmounting IssuableList
      if (!this.hasAnyIssues) {
        this.isInitialAllCountSet = false;
      }
      this.$apollo.queries.workItems.refetch();
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
    fetchLabelsWithFetchPolicy(search, fetchPolicy = fetchPolicies.CACHE_FIRST) {
      return this.$apollo
        .query({
          query: searchLabelsQuery,
          variables: { fullPath: this.fullPath, search, isProject: !this.isGroup },
          fetchPolicy,
        })
        .then(({ data }) => {
          // TODO remove once we can search by title-only on the backend
          // https://gitlab.com/gitlab-org/gitlab/-/issues/346353
          const labels = data[this.namespace]?.labels.nodes;
          return labels.filter((label) => label.title.toLowerCase().includes(search.toLowerCase()));
        });
    },
    fetchLabels(search) {
      return this.fetchLabelsWithFetchPolicy(search);
    },
    fetchLatestLabels(search) {
      return this.fetchLabelsWithFetchPolicy(search, fetchPolicies.NETWORK_ONLY);
    },
    getStatus(issue) {
      return issue.state === STATE_CLOSED ? __('Closed') : undefined;
    },
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }

      this.state = state;
      this.pageParams = getInitialPageParams(this.pageSize);
    },
    handleFilter(tokens) {
      this.filterTokens = tokens;
      this.pageParams = getInitialPageParams(this.pageSize);
    },
    handleNextPage() {
      this.pageParams = {
        afterCursor: this.pageInfo.endCursor,
        firstPageSize: this.pageSize,
      };
      scrollUp();
    },
    handlePageSizeChange(pageSize) {
      this.pageSize = pageSize;
      this.pageParams = getInitialPageParams(pageSize);
      scrollUp();
    },
    handlePreviousPage() {
      this.pageParams = {
        beforeCursor: this.pageInfo.startCursor,
        lastPageSize: this.pageSize,
      };
      scrollUp();
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
    redirectToWorkItem(workItem) {
      const regex = /groups\/.+?\/-\/work_items\/\d+/;
      const isWorkItemPath = regex.test(workItem.webUrl);

      if (isWorkItemPath) {
        this.$router.push({
          name: 'workItem',
          params: {
            iid: workItem.iid,
          },
        });
      } else {
        visitUrl(workItem.webUrl);
      }
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="!isInitialAllCountSet && !error" class="gl-mt-5" size="lg" />

  <issuable-list
    v-else-if="hasAnyIssues || error"
    :current-tab="state"
    :default-page-size="pageSize"
    :error="error"
    :has-next-page="pageInfo.hasNextPage"
    :has-previous-page="pageInfo.hasPreviousPage"
    :initial-sort-by="sortKey"
    :issuables="workItems"
    :issuables-loading="isLoading"
    :show-bulk-edit-sidebar="showBulkEditSidebar"
    namespace="work-items"
    recent-searches-storage-key="issues"
    :search-tokens="searchTokens"
    show-filtered-search-friendly-text
    :show-page-size-selector="showPageSizeSelector"
    :show-pagination-controls="showPaginationControls"
    show-work-item-type-icon
    :sort-options="$options.sortOptions"
    :tab-counts="tabCounts"
    :tabs="$options.issuableListTabs"
    use-keyset-pagination
    prevent-redirect
    @click-tab="handleClickTab"
    @dismiss-alert="error = undefined"
    @filter="handleFilter"
    @next-page="handleNextPage"
    @page-size-change="handlePageSizeChange"
    @previous-page="handlePreviousPage"
    @sort="handleSort"
    @select-issuable="redirectToWorkItem"
  >
    <template #nav-actions>
      <slot name="nav-actions"></slot>
    </template>

    <template #timeframe="{ issuable = {} }">
      <issue-card-time-info :issue="issuable" />
    </template>

    <template #status="{ issuable }">
      {{ getStatus(issuable) }}
    </template>

    <template #statistics="{ issuable = {} }">
      <issue-card-statistics :issue="issuable" />
    </template>

    <template #empty-state>
      <slot name="list-empty-state" :has-search="hasSearch" :is-open-tab="isOpenTab"></slot>
    </template>

    <template #list-body>
      <slot name="list-body"></slot>
    </template>

    <template #bulk-edit-actions="{ checkedIssuables }">
      <slot name="bulk-edit-actions" :checked-issuables="checkedIssuables"></slot>
    </template>

    <template #sidebar-items="{ checkedIssuables }">
      <slot name="sidebar-items" :checked-issuables="checkedIssuables"></slot>
    </template>
  </issuable-list>

  <div v-else>
    <slot name="page-empty-state"></slot>
  </div>
</template>
