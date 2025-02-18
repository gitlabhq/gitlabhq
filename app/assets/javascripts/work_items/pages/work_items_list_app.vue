<script>
import { GlFilteredSearchToken, GlLoadingIcon } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import WorkItemHealthStatus from '~/work_items/components/work_item_health_status.vue';
import {
  convertToApiParams,
  convertToSearchQuery,
  deriveSortKey,
  getDefaultWorkItemTypes,
  getInitialPageParams,
  getTypeTokenOptions,
  getFilterTokens,
  convertToUrlParams,
} from 'ee_else_ce/issues/list/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  STATUS_ALL,
  STATUS_CLOSED,
  STATUS_OPEN,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import { AutocompleteCache } from '~/issues/dashboard/utils';
import {
  CREATED_DESC,
  PARAM_FIRST_PAGE_SIZE,
  PARAM_LAST_PAGE_SIZE,
  PARAM_PAGE_AFTER,
  PARAM_PAGE_BEFORE,
  PARAM_STATE,
  PARAM_SORT,
} from '~/issues/list/constants';
import searchLabelsQuery from '~/issues/list/queries/search_labels.query.graphql';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { fetchPolicies } from '~/lib/graphql';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { __, s__ } from '~/locale';
import {
  OPERATOR_IS,
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
  TOKEN_TITLE_STATE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_GROUP,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_STATE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import { DEFAULT_PAGE_SIZE, issuableListTabs } from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import {
  STATE_CLOSED,
  STATE_OPEN,
  WORK_ITEM_TYPE_ENUM_EPIC,
  DETAIL_VIEW_QUERY_PARAM_NAME,
} from '../constants';
import getWorkItemsQuery from '../graphql/list/get_work_items.query.graphql';
import getWorkItemStateCountsQuery from '../graphql/list/get_work_item_state_counts.query.graphql';
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

const statusMap = {
  [STATUS_OPEN]: STATE_OPEN,
  [STATUS_CLOSED]: STATE_CLOSED,
};

export default {
  issuableListTabs,
  sortOptions,
  components: {
    GlLoadingIcon,
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
    WorkItemDrawer,
    WorkItemHealthStatus,
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
    withTabs: {
      type: Boolean,
      required: false,
      default: true,
    },
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      error: undefined,
      filterTokens: [],
      hasAnyIssues: false,
      isInitialLoadComplete: false,
      pageInfo: {},
      pageParams: {},
      pageSize: DEFAULT_PAGE_SIZE,
      sortKey: CREATED_DESC,
      state: STATUS_OPEN,
      workItems: [],
      workItemStateCounts: {},
      activeItem: null,
      isRefetching: false,
      hasStateToken: false,
    };
  },
  apollo: {
    workItems: {
      query: getWorkItemsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.[this.namespace].workItems.nodes ?? [];
      },
      skip() {
        return isEmpty(this.pageParams);
      },
      result({ data }) {
        this.pageInfo = data?.[this.namespace].workItems.pageInfo ?? {};

        if (data?.[this.namespace]) {
          if (this.isGroup) {
            const rootBreadcrumbName = this.isEpicsList ? __('Epics') : s__('WorkItem|Work items');
            document.title = `${rootBreadcrumbName} · ${data.group.name} · GitLab`;
          } else {
            document.title = `Issues · ${data.project.name} · GitLab`;
          }
        }
        if (!this.withTabs) {
          this.hasAnyIssues = Boolean(data?.[this.namespace].workItems.nodes);
          this.isInitialLoadComplete = true;
        }
        this.checkDrawerParams();
      },
      error(error) {
        this.error = s__(
          'WorkItem|Something went wrong when fetching work items. Please try again.',
        );
        Sentry.captureException(error);
      },
    },
    workItemStateCounts: {
      query: getWorkItemStateCountsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.[this.namespace].workItemStateCounts ?? {};
      },
      skip() {
        return isEmpty(this.pageParams) || !this.withTabs;
      },
      result({ data }) {
        const { all } = data?.[this.namespace].workItemStateCounts ?? {};

        if (!this.isInitialLoadComplete) {
          this.hasAnyIssues = Boolean(all);
          this.isInitialLoadComplete = true;
        }
      },
      error(error) {
        this.error = s__('WorkItem|An error occurred while getting work item counts.');
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isItemSelected() {
      return !isEmpty(this.activeItem);
    },
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
    workItemDrawerEnabled() {
      if (gon.current_user_use_work_items_view) return true;
      return this.isEpicsList ? this.glFeatures.epicsListDrawer : this.glFeatures.issuesListDrawer;
    },
    isEpicsList() {
      return this.workItemType === WORK_ITEM_TYPE_ENUM_EPIC;
    },
    hasSearch() {
      return Boolean(this.searchQuery);
    },
    isLoading() {
      return this.$apollo.queries.workItems.loading && !this.isRefetching;
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
    },
    namespace() {
      return this.isGroup ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
    queryVariables() {
      return {
        fullPath: this.fullPath,
        sort: this.sortKey,
        state: this.state,
        search: this.searchQuery,
        ...this.apiFilterParams,
        ...this.pageParams,
        excludeProjects: this.isEpicsList,
        includeDescendants: !this.apiFilterParams.fullPath,
        types: this.apiFilterParams.types || this.workItemType || this.defaultWorkItemTypes,
        isGroup: this.isGroup,
      };
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

      if (this.isGroup) {
        tokens.push({
          type: TOKEN_TYPE_GROUP,
          icon: 'group',
          title: TOKEN_TITLE_GROUP,
          unique: true,
          token: GroupToken,
          operators: OPERATORS_IS,
          fullPath: this.fullPath,
        });
      }

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

      if (!this.withTabs) {
        tokens.push({
          type: TOKEN_TYPE_STATE,
          title: TOKEN_TITLE_STATE,
          icon: 'issue-open-m',
          unique: true,
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          options: [
            { value: STATUS_ALL, title: __('Any') },
            { value: STATUS_OPEN, title: __('Open') },
            { value: STATUS_CLOSED, title: __('Closed') },
          ],
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
    tabCounts() {
      const { all, closed, opened } = this.workItemStateCounts;
      return {
        [STATUS_OPEN]: opened,
        [STATUS_CLOSED]: closed,
        [STATUS_ALL]: all,
      };
    },
    typeTokenOptions() {
      return getTypeTokenOptions({
        hasEpicsFeature: this.hasEpicsFeature,
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
        first_page_size: this.pageParams.firstPageSize,
        last_page_size: this.pageParams.lastPageSize,
        page_after: this.pageParams.afterCursor ?? undefined,
        page_before: this.pageParams.beforeCursor ?? undefined,
      };
    },
    activeWorkItemType() {
      const activeWorkItemTypeName =
        typeof this.activeItem?.workItemType === 'object'
          ? this.activeItem?.workItemType?.name
          : this.activeItem?.workItemType;
      return this.workItemType || activeWorkItemTypeName;
    },
    tabs() {
      if (this.withTabs) {
        return this.$options.issuableListTabs;
      }
      return [];
    },
  },
  watch: {
    eeWorkItemUpdateCount() {
      // Only reset isInitialLoadComplete when there's no issues to minimize unmounting IssuableList
      if (!this.hasAnyIssues) {
        this.isInitialLoadComplete = false;
      }
      this.$apollo.queries.workItems.refetch();
    },
    $route(newValue, oldValue) {
      if (newValue.fullPath !== oldValue.fullPath) {
        this.updateData(getParameterByName(PARAM_SORT));
      }
      if (newValue.query[DETAIL_VIEW_QUERY_PARAM_NAME] && !this.$apollo.queries.workItems.loading) {
        this.checkDrawerParams();
      } else {
        this.activeItem = null;
      }
    },
  },
  created() {
    this.updateData(this.initialSort);
    this.addStateToken();
    this.autocompleteCache = new AutocompleteCache();
  },
  methods: {
    handleSelect(item) {
      this.activeItem = item;
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

      this.$router.push({ query: this.urlParams });
    },
    handleFilter(tokens) {
      this.filterTokens = tokens;
      this.hasStateToken = this.checkIfStateTokenExists();
      this.updateState(tokens);
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
    handlePageSizeChange(pageSize) {
      this.pageSize = pageSize;
      this.pageParams = getInitialPageParams(pageSize);
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
    deleteItem() {
      this.activeItem = null;
      this.refetchItems();
    },
    handleStatusChange(workItem) {
      if (this.state === STATUS_ALL) {
        return;
      }
      if (statusMap[this.state] !== workItem.state) {
        this.refetchItems();
      }
    },
    async refetchItems() {
      this.isRefetching = true;
      await this.$apollo.queries.workItems.refetch();
      this.isRefetching = false;
    },
    updateData(sort) {
      const firstPageSize = getParameterByName(PARAM_FIRST_PAGE_SIZE);
      const lastPageSize = getParameterByName(PARAM_LAST_PAGE_SIZE);
      const state = getParameterByName(PARAM_STATE);

      this.filterTokens = getFilterTokens(window.location.search, !this.withTabs);
      if (!this.hasStateToken && this.state === STATUS_ALL) {
        this.filterTokens = this.filterTokens.filter(
          (filterToken) => filterToken.type !== TOKEN_TYPE_STATE,
        );
      }

      this.pageParams = getInitialPageParams(
        this.pageSize,
        isPositiveInteger(firstPageSize) ? parseInt(firstPageSize, 10) : undefined,
        isPositiveInteger(lastPageSize) ? parseInt(lastPageSize, 10) : undefined,
        getParameterByName(PARAM_PAGE_AFTER) ?? undefined,
        getParameterByName(PARAM_PAGE_BEFORE) ?? undefined,
      );

      // Trigger pageSize UI component update based on URL changes
      this.pageSize = this.pageParams.firstPageSize;
      this.sortKey = deriveSortKey({ sort, sortMap: urlSortParams });
      this.state = state || STATUS_OPEN;
    },
    checkDrawerParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (!queryParam) {
        return;
      }

      const params = JSON.parse(atob(queryParam));
      if (params.id) {
        const issue = this.workItems.find((i) => getIdFromGraphQLId(i.id) === params.id);
        if (issue) {
          this.activeItem = {
            ...issue,
            // we need fullPath here to prevent cache invalidation
            fullPath: params.full_path,
          };
        } else {
          updateHistory({
            url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
          });
        }
      }
    },
    updateState(tokens) {
      if (!this.withTabs) {
        this.state =
          tokens.find((token) => token.type === TOKEN_TYPE_STATE)?.value.data || STATUS_ALL;
      }
    },
    addStateToken() {
      this.hasStateToken = this.checkIfStateTokenExists();
      if (!this.withTabs && !this.hasStateToken) {
        this.filterTokens.push({
          type: TOKEN_TYPE_STATE,
          value: {
            data: STATUS_OPEN,
            operator: OPERATOR_IS,
          },
        });
      }
    },
    checkIfStateTokenExists() {
      return this.filterTokens.some((filterToken) => filterToken.type === TOKEN_TYPE_STATE);
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="!isInitialLoadComplete && !error" class="gl-mt-5" size="lg" />

  <div v-else-if="hasAnyIssues || error">
    <work-item-drawer
      v-if="workItemDrawerEnabled"
      :active-item="activeItem"
      :open="isItemSelected"
      :issuable-type="activeWorkItemType"
      :new-comment-template-paths="newCommentTemplatePaths"
      click-outside-exclude-selector=".issuable-list"
      @close="activeItem = null"
      @addChild="refetchItems"
      @workItemDeleted="deleteItem"
      @work-item-updated="handleStatusChange"
    />
    <issuable-list
      :active-issuable="activeItem"
      :add-padding="!withTabs"
      :current-tab="state"
      :default-page-size="pageSize"
      :error="error"
      :has-next-page="pageInfo.hasNextPage"
      :has-previous-page="pageInfo.hasPreviousPage"
      :initial-filter-value="filterTokens"
      :initial-sort-by="sortKey"
      :issuables="workItems"
      :issuables-loading="isLoading"
      :show-bulk-edit-sidebar="showBulkEditSidebar"
      namespace="work-items"
      :full-path="fullPath"
      recent-searches-storage-key="issues"
      :search-tokens="searchTokens"
      show-filtered-search-friendly-text
      :show-page-size-selector="showPageSizeSelector"
      :show-pagination-controls="showPaginationControls"
      show-work-item-type-icon
      :sort-options="$options.sortOptions"
      sync-filter-and-sort
      :tab-counts="tabCounts"
      :tabs="tabs"
      use-keyset-pagination
      :prevent-redirect="workItemDrawerEnabled"
      @click-tab="handleClickTab"
      @dismiss-alert="error = undefined"
      @filter="handleFilter"
      @next-page="handleNextPage"
      @page-size-change="handlePageSizeChange"
      @previous-page="handlePreviousPage"
      @sort="handleSort"
      @select-issuable="handleSelect"
    >
      <template #nav-actions>
        <slot name="nav-actions"></slot>
      </template>

      <template #timeframe="{ issuable = {} }">
        <issue-card-time-info :issue="issuable" :is-work-item-list="true" />
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

      <template #health-status="{ issuable = {} }">
        <work-item-health-status :issue="issuable" />
      </template>
    </issuable-list>
  </div>

  <div v-else>
    <slot name="page-empty-state"></slot>
  </div>
</template>
