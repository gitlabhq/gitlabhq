<script>
import { GlButton, GlFilteredSearchToken, GlLoadingIcon } from '@gitlab/ui';
import { isEmpty, unionBy } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
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
import { TYPENAME_NAMESPACE, TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  STATUS_ALL,
  STATUS_CLOSED,
  STATUS_OPEN,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import { AutocompleteCache } from '~/issues/dashboard/utils';
import EmptyStateWithoutAnyIssues from '~/issues/list/components/empty_state_without_any_issues.vue';
import {
  CREATED_DESC,
  PARAM_FIRST_PAGE_SIZE,
  PARAM_LAST_PAGE_SIZE,
  PARAM_PAGE_AFTER,
  PARAM_PAGE_BEFORE,
  PARAM_SORT,
  PARAM_STATE,
  urlSortParams,
} from '~/issues/list/constants';
import searchLabelsQuery from '~/issues/list/queries/search_labels.query.graphql';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { fetchPolicies } from '~/lib/graphql';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  OPERATOR_IS,
  OPERATORS_AFTER_BEFORE,
  OPERATORS_IS,
  OPERATORS_IS_NOT,
  OPERATORS_IS_NOT_OR,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CLOSED,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_CREATED,
  TOKEN_TITLE_DUE_DATE,
  TOKEN_TITLE_GROUP,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_SEARCH_WITHIN,
  TOKEN_TITLE_STATE,
  TOKEN_TITLE_SUBSCRIBED,
  TOKEN_TITLE_TYPE,
  TOKEN_TITLE_UPDATED,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CLOSED,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_CREATED,
  TOKEN_TYPE_DUE_DATE,
  TOKEN_TYPE_GROUP,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_STATE,
  TOKEN_TYPE_SUBSCRIBED,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_UPDATED,
} from '~/vue_shared/components/filtered_search_bar/constants';
import DateToken from '~/vue_shared/components/filtered_search_bar/tokens/date_token.vue';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { DEFAULT_PAGE_SIZE, issuableListTabs } from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getWorkItemStateCountsQuery from 'ee_else_ce/work_items/graphql/list/get_work_item_state_counts.query.graphql';
import getWorkItemsQuery from 'ee_else_ce/work_items/graphql/list/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/graphql/list/get_work_items_slim.query.graphql';
import CreateWorkItemModal from '../components/create_work_item_modal.vue';
import WorkItemHealthStatus from '../components/work_item_health_status.vue';
import WorkItemDrawer from '../components/work_item_drawer.vue';
import WorkItemListHeading from '../components/work_item_list_heading.vue';
import {
  BASE_ALLOWED_CREATE_TYPES,
  DETAIL_VIEW_QUERY_PARAM_NAME,
  NAME_TO_ENUM_MAP,
  STATE_CLOSED,
  STATE_OPEN,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_KEY_RESULT,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
} from '../constants';

const EmojiToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue');
const GroupToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/group_token.vue');
const LabelToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue');
const MilestoneToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue');
const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');
const LocalBoard = () => import('./local_board/local_board.vue');

const statusMap = {
  [STATUS_OPEN]: STATE_OPEN,
  [STATUS_CLOSED]: STATE_CLOSED,
};

export default {
  issuableListTabs,
  components: {
    GlLoadingIcon,
    GlButton,
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
    WorkItemBulkEditSidebar: () =>
      import('~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_sidebar.vue'),
    WorkItemDrawer,
    WorkItemHealthStatus,
    EmptyStateWithoutAnyIssues,
    CreateWorkItemModal,
    LocalBoard,
    WorkItemListHeading,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'autocompleteAwardEmojisPath',
    'canBulkUpdate',
    'canBulkEditEpics',
    'hasBlockedIssuesFeature',
    'hasEpicsFeature',
    'hasGroupBulkEditFeature',
    'hasIssuableHealthStatusFeature',
    'hasIssueDateFilterFeature',
    'hasIssueWeightsFeature',
    'hasOkrsFeature',
    'hasQualityManagementFeature',
    'hasCustomFieldsFeature',
    'initialSort',
    'isGroup',
    'isSignedIn',
    'showNewWorkItem',
    'workItemType',
  ],
  props: {
    eeWorkItemUpdateCount: {
      type: Number,
      required: false,
      default: 0,
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
    eeSearchTokens: {
      type: Array,
      required: false,
      default: () => [],
    },
    rootPageFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      error: undefined,
      bulkEditInProgress: false,
      filterTokens: [],
      hasAnyIssues: false,
      isInitialLoadComplete: false,
      pageInfo: {},
      pageParams: {},
      pageSize: DEFAULT_PAGE_SIZE,
      showBulkEditSidebar: false,
      sortKey: CREATED_DESC,
      state: STATUS_OPEN,
      workItemsFull: [],
      workItemsSlim: [],
      workItemStateCounts: {},
      activeItem: null,
      isRefetching: false,
      hasStateToken: false,
      initialLoadWasFiltered: false,
      showLocalBoard: false,
      namespaceId: null,
    };
  },
  apollo: {
    workItemsFull: {
      query() {
        return getWorkItemsQuery;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.namespace.workItems.nodes ?? [];
      },
      skip() {
        return isEmpty(this.pageParams);
      },
      result({ data }) {
        this.namespaceId = data?.namespace?.id;
        this.handleListDataResults(data);
      },
      error(error) {
        this.error = s__(
          'WorkItem|Something went wrong when fetching work items. Please try again.',
        );
        Sentry.captureException(error);
      },
    },
    workItemsSlim: {
      query() {
        return getWorkItemsSlimQuery;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.namespace.workItems.nodes ?? [];
      },
      skip() {
        return isEmpty(this.pageParams);
      },
      result({ data }) {
        this.handleListDataResults(data);
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
          this.initialLoadWasFiltered = this.filterTokens.length > 0;
        }
      },
      error(error) {
        this.error = s__('WorkItem|An error occurred while getting work item counts.');
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    workItems() {
      if (this.workItemsFull.length > 0 && this.workItemsSlim.length > 0 && !this.detailLoading) {
        return this.combineSlimAndFullLists(this.workItemsSlim, this.workItemsFull);
      }
      return this.workItemsSlim;
    },
    shouldShowList() {
      return (
        this.hasAnyIssues || this.error || this.initialLoadWasFiltered || this.workItems.length > 0
      );
    },
    detailLoading() {
      return this.$apollo.queries.workItemsFull.loading;
    },
    isItemSelected() {
      return !isEmpty(this.activeItem);
    },
    allowBulkEditing() {
      if (this.isEpicsList) {
        return this.canBulkEditEpics;
      }
      if (this.isGroup) {
        return this.canBulkUpdate && this.hasGroupBulkEditFeature;
      }
      return this.canBulkUpdate;
    },
    // TODO: delete once https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185081 is merged
    allowedWorkItemTypes() {
      if (this.isGroup) {
        return [];
      }

      if (this.glFeatures.okrsMvc && this.hasOkrsFeature) {
        return BASE_ALLOWED_CREATE_TYPES.concat(
          WORK_ITEM_TYPE_NAME_KEY_RESULT,
          WORK_ITEM_TYPE_NAME_OBJECTIVE,
        );
      }

      return BASE_ALLOWED_CREATE_TYPES;
    },
    apiFilterParams() {
      return convertToApiParams(this.filterTokens, {
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
      });
    },
    defaultWorkItemTypes() {
      return getDefaultWorkItemTypes({
        hasEpicsFeature: this.hasEpicsFeature,
        hasOkrsFeature: this.hasOkrsFeature,
        hasQualityManagementFeature: this.hasQualityManagementFeature,
      });
    },
    workItemDrawerEnabled() {
      if (this.glFeatures.workItemViewForIssues) {
        return true;
      }
      return this.isEpicsList
        ? this.glFeatures?.epicsListDrawer
        : this.glFeatures?.issuesListDrawer;
    },
    isEpicsList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
    },
    hasSearch() {
      return Boolean(this.searchQuery);
    },
    isLoading() {
      return this.$apollo.queries.workItemsSlim.loading && !this.isRefetching;
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
    },
    namespace() {
      return this.isGroup ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
    queryVariables() {
      const hasGroupFilter = Boolean(this.urlFilterParams.group_path);
      const singleWorkItemType = this.workItemType ? NAME_TO_ENUM_MAP[this.workItemType] : null;
      return {
        fullPath: this.rootPageFullPath,
        sort: this.sortKey,
        state: this.state,
        search: this.searchQuery,
        ...this.apiFilterParams,
        ...this.pageParams,
        excludeProjects: hasGroupFilter || this.isEpicsList,
        includeDescendants: !hasGroupFilter,
        types: this.apiFilterParams.types || singleWorkItemType || this.defaultWorkItemTypes,
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
          fullPath: this.rootPageFullPath,
          isProject: !this.isGroup,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-assignee`,
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
          fullPath: this.rootPageFullPath,
          isProject: !this.isGroup,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-author`,
          preloadedUsers,
        },
        {
          type: TOKEN_TYPE_LABEL,
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
          operators: OPERATORS_IS_NOT_OR,
          fetchLabels: this.fetchLabels,
          fetchLatestLabels: this.fetchLatestLabels,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-label`,
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          token: MilestoneToken,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-milestone`,
          shouldSkipSort: true,
          fullPath: this.rootPageFullPath,
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
          fullPath: this.rootPageFullPath,
        });
      }

      if (!this.workItemType) {
        tokens.push({
          type: TOKEN_TYPE_TYPE,
          title: TOKEN_TITLE_TYPE,
          icon: 'issues',
          unique: true,
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS_NOT,
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
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-my_reaction`,
        });

        tokens.push({
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

      if (this.hasIssueDateFilterFeature) {
        tokens.push({
          type: TOKEN_TYPE_CLOSED,
          title: TOKEN_TITLE_CLOSED,
          icon: 'history',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });

        tokens.push({
          type: TOKEN_TYPE_CREATED,
          title: TOKEN_TITLE_CREATED,
          icon: 'history',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });

        tokens.push({
          type: TOKEN_TYPE_DUE_DATE,
          title: TOKEN_TITLE_DUE_DATE,
          icon: 'calendar',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });

        tokens.push({
          type: TOKEN_TYPE_UPDATED,
          title: TOKEN_TITLE_UPDATED,
          icon: 'history',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });
      }

      if (this.eeSearchTokens.length) {
        tokens.push(...this.eeSearchTokens);
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
    sortOptions() {
      return getSortOptions({
        hasBlockedIssuesFeature: this.hasBlockedIssuesFeature,
        hasIssuableHealthStatusFeature: this.hasIssuableHealthStatusFeature,
        hasIssueWeightsFeature: this.hasIssueWeightsFeature,
        hasManualSort: false,
        hasStartDate: true,
        hasPriority: !this.isEpicsList,
        hasMilestoneDueDate: true,
        hasLabelPriority: !this.isEpicsList,
        hasWeight: !this.isEpicsList,
      });
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
      return convertToUrlParams(this.filterTokens, {
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
      });
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
    enableClientSideBoardsExperiment() {
      return this.glFeatures.workItemsClientSideBoards;
    },
    isPlanningViewsEnabled() {
      return this.glFeatures.workItemPlanningView;
    },
    preselectedWorkItemType() {
      return this.isEpicsList ? WORK_ITEM_TYPE_NAME_EPIC : WORK_ITEM_TYPE_NAME_ISSUE;
    },
  },
  watch: {
    eeWorkItemUpdateCount() {
      // Only reset isInitialLoadComplete when there's no issues to minimize unmounting IssuableList
      if (!this.hasAnyIssues) {
        this.isInitialLoadComplete = false;
      }
      this.$apollo.queries.workItemStateCounts.refetch();
      this.$apollo.queries.workItemsFull.refetch();
      this.$apollo.queries.workItemsSlim.refetch();
    },
    $route(newValue, oldValue) {
      if (newValue.fullPath !== oldValue.fullPath) {
        this.updateData(getParameterByName(PARAM_SORT));
      }
      if (newValue.query[DETAIL_VIEW_QUERY_PARAM_NAME] && !this.detailLoading) {
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
    window.addEventListener('popstate', this.checkDrawerParams);
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.checkDrawerParams);
  },
  methods: {
    combineSlimAndFullLists(slim, full) {
      const findSlimItem = (id) => slim.find((item) => item.id === id);
      return full.map((fullItem) => {
        const slimVersion = findSlimItem(fullItem.id);
        const combinedWidgets = unionBy(fullItem.widgets, slimVersion?.widgets, 'type');
        return {
          ...fullItem,
          widgets: combinedWidgets.reduce((acc, widget) => {
            const slimWidget = slimVersion?.widgets.find((w) => w.type === widget.type);
            if (slimWidget && Object.keys(slimWidget).length > Object.keys(widget).length) {
              acc.push(slimWidget);
            } else {
              acc.push(widget);
            }
            return acc;
          }, []),
        };
      });
    },
    handleListDataResults(listData) {
      this.pageInfo = listData?.namespace.workItems.pageInfo ?? {};

      if (listData?.namespace) {
        document.title = this.calculateDocumentTitle(listData);
      }
      if (!this.withTabs) {
        this.hasAnyIssues = Boolean(listData?.namespace.workItems.nodes);
        this.isInitialLoadComplete = true;
      }
      this.checkDrawerParams();
    },
    handleToggle(item) {
      if (item && this.activeItem?.iid === item.iid) {
        this.activeItem = null;
        const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);
        if (queryParam) {
          updateHistory({
            url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
          });
        }
      } else {
        this.activeItem = item;
      }
    },
    calculateDocumentTitle(data) {
      const middleCrumb = data.namespace.name;
      if (this.isPlanningViewsEnabled) {
        return `${s__('WorkItem|Work items')} · ${middleCrumb} · GitLab`;
      }
      if (this.isGroup && this.isEpicsList) {
        return `${__('Epics')} · ${middleCrumb} · GitLab`;
      }
      if (this.isGroup) {
        return `${s__('WorkItem|Work items')} · ${middleCrumb} · GitLab`;
      }
      return `${__('Issues')} · ${middleCrumb} · GitLab`;
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
          variables: { fullPath: this.rootPageFullPath, search, isProject: !this.isGroup },
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
    async handleBulkEditSuccess(event) {
      this.showBulkEditSidebar = false;
      this.refetchItems(event);
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
      this.refetchItems({ refetchCounts: true });
    },
    handleStatusChange(workItem) {
      if (this.state === STATUS_ALL) {
        return;
      }
      if (statusMap[this.state] !== workItem.state) {
        this.refetchItems({ refetchCounts: true });
      }
    },
    async refetchItems({ refetchCounts = false } = {}) {
      if (refetchCounts) {
        this.$apollo.queries.workItemStateCounts.refetch();
      }

      // evict the namespace's workItems cache to force a full refetch
      const { cache } = this.$apollo.provider.defaultClient;
      cache.evict({
        id: cache.identify({ __typename: TYPENAME_NAMESPACE, id: this.namespaceId }),
        fieldName: 'workItems',
      });
      cache.gc();
    },
    updateData(sort) {
      const firstPageSize = getParameterByName(PARAM_FIRST_PAGE_SIZE);
      const lastPageSize = getParameterByName(PARAM_LAST_PAGE_SIZE);
      const state = getParameterByName(PARAM_STATE);

      this.filterTokens = getFilterTokens(window.location.search, {
        includeStateToken: !this.withTabs,
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
      });
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
      this.sortKey = deriveSortKey({ sort });
      this.state = state || STATUS_OPEN;
    },
    checkDrawerParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (!queryParam) {
        this.activeItem = null;
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
    handleWorkItemCreated() {
      this.isInitialLoadComplete = false;
      this.refetchItems({ refetchCounts: true });
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="!isInitialLoadComplete && !error" class="gl-mt-5" size="lg" />

  <div v-else-if="shouldShowList">
    <div v-if="showLocalBoard">
      <local-board :work-item-list-data="workItems" @back="showLocalBoard = false" />
    </div>
    <template v-else>
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
        :full-path="rootPageFullPath"
        recent-searches-storage-key="issues"
        :search-tokens="searchTokens"
        show-filtered-search-friendly-text
        :show-page-size-selector="showPageSizeSelector"
        :show-pagination-controls="showPaginationControls"
        show-work-item-type-icon
        :sort-options="sortOptions"
        sync-filter-and-sort
        :tab-counts="tabCounts"
        :tabs="tabs"
        use-keyset-pagination
        :prevent-redirect="workItemDrawerEnabled"
        :detail-loading="detailLoading"
        @click-tab="handleClickTab"
        @dismiss-alert="error = undefined"
        @filter="handleFilter"
        @next-page="handleNextPage"
        @page-size-change="handlePageSizeChange"
        @previous-page="handlePreviousPage"
        @sort="handleSort"
        @select-issuable="handleToggle"
      >
        <template v-if="!isPlanningViewsEnabled" #nav-actions>
          <div class="gl-flex gl-gap-3">
            <gl-button
              v-if="enableClientSideBoardsExperiment"
              data-testid="show-local-board-button"
              @click="showLocalBoard = true"
            >
              {{ __('Launch board') }}
            </gl-button>
            <gl-button
              v-if="allowBulkEditing"
              :disabled="showBulkEditSidebar"
              data-testid="bulk-edit-start-button"
              @click="showBulkEditSidebar = true"
            >
              {{ __('Bulk edit') }}
            </gl-button>
            <create-work-item-modal
              v-if="showNewWorkItem"
              :allowed-work-item-types="allowedWorkItemTypes"
              :always-show-work-item-type-select="!isEpicsList"
              :full-path="rootPageFullPath"
              :is-group="isGroup"
              :preselected-work-item-type="preselectedWorkItemType"
              @workItemCreated="refetchItems"
            />
          </div>
        </template>

        <template v-if="isPlanningViewsEnabled" #list-header>
          <work-item-list-heading>
            <div class="gl-flex gl-gap-3">
              <gl-button
                v-if="enableClientSideBoardsExperiment"
                data-testid="show-local-board-button"
                @click="showLocalBoard = true"
              >
                {{ __('Launch board') }}
              </gl-button>
              <gl-button
                v-if="allowBulkEditing"
                :disabled="showBulkEditSidebar"
                data-testid="bulk-edit-start-button"
                @click="showBulkEditSidebar = true"
              >
                {{ __('Bulk edit') }}
              </gl-button>
              <create-work-item-modal
                v-if="showNewWorkItem"
                :allowed-work-item-types="allowedWorkItemTypes"
                :always-show-work-item-type-select="!isEpicsList"
                :full-path="rootPageFullPath"
                :is-group="isGroup"
                :preselected-work-item-type="preselectedWorkItemType"
                @workItemCreated="refetchItems"
              />
            </div>
          </work-item-list-heading>
        </template>

        <template #timeframe="{ issuable = {} }">
          <issue-card-time-info
            :issue="issuable"
            :is-work-item-list="true"
            :detail-loading="detailLoading"
          />
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
          <gl-button
            :disabled="!checkedIssuables.length || bulkEditInProgress"
            form="work-item-list-bulk-edit"
            :loading="bulkEditInProgress"
            type="submit"
            variant="confirm"
          >
            {{ __('Update selected') }}
          </gl-button>
          <gl-button class="gl-float-right" @click="showBulkEditSidebar = false">
            {{ __('Cancel') }}
          </gl-button>
        </template>

        <template #sidebar-items="{ checkedIssuables }">
          <work-item-bulk-edit-sidebar
            v-if="showBulkEditSidebar"
            :checked-items="checkedIssuables"
            :full-path="rootPageFullPath"
            :is-epics-list="isEpicsList"
            :is-group="isGroup"
            @finish="bulkEditInProgress = false"
            @start="bulkEditInProgress = true"
            @success="handleBulkEditSuccess"
          />
        </template>

        <template #health-status="{ issuable = {} }">
          <work-item-health-status :issue="issuable" />
        </template>
      </issuable-list>
    </template>
  </div>

  <div v-else>
    <slot name="page-empty-state">
      <empty-state-without-any-issues>
        <template #new-issue-button>
          <create-work-item-modal
            :full-path="rootPageFullPath"
            :is-group="isGroup"
            :preselected-work-item-type="preselectedWorkItemType"
            @workItemCreated="handleWorkItemCreated"
          />
        </template>
      </empty-state-without-any-issues>
    </slot>
  </div>
</template>
