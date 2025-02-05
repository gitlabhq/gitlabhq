<script>
import {
  GlButton,
  GlButtonGroup,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlFilteredSearchToken,
  GlTooltipDirective,
} from '@gitlab/ui';

import produce from 'immer';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { isEmpty } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import getIssuesCountsQuery from 'ee_else_ce/issues/list/queries/get_issues_counts.query.graphql';
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
  groupMultiSelectFilterTokens,
  mapWorkItemWidgetsToIssuableFields,
  updateUpvotesCount,
} from 'ee_else_ce/issues/list/utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { createAlert, VARIANT_INFO } from '~/alert';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import {
  STATUS_ALL,
  STATUS_CLOSED,
  STATUS_OPEN,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
  TYPE_ISSUE,
} from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import { fetchPolicies } from '~/lib/graphql';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import {
  getParameterByName,
  joinPaths,
  removeParams,
  updateHistory,
} from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  OPERATORS_IS,
  OPERATORS_IS_NOT_OR,
  OPERATORS_AFTER_BEFORE,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_CONTACT,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_ORGANIZATION,
  TOKEN_TITLE_RELEASE,
  TOKEN_TITLE_SEARCH_WITHIN,
  TOKEN_TITLE_TYPE,
  TOKEN_TITLE_CREATED,
  TOKEN_TITLE_CLOSED,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_CONTACT,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_ORGANIZATION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_CREATED,
  TOKEN_TYPE_CLOSED,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { DEFAULT_PAGE_SIZE, issuableListTabs } from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import {
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  DETAIL_VIEW_QUERY_PARAM_NAME,
  INJECTION_LINK_CHILD_PREVENT_ROUTER_NAVIGATION,
} from '~/work_items/constants';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import { makeDrawerUrlParam } from '~/work_items/utils';
import {
  CREATED_DESC,
  i18n,
  ISSUE_REFERENCE,
  ISSUES_GRID_VIEW_KEY,
  ISSUES_LIST_VIEW_KEY,
  ISSUES_VIEW_TYPE_KEY,
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
} from '../constants';
import eventHub from '../eventhub';
import reorderIssuesMutation from '../queries/reorder_issues.mutation.graphql';
import searchLabelsQuery from '../queries/search_labels.query.graphql';
import setSortPreferenceMutation from '../queries/set_sort_preference.mutation.graphql';
import { hasNewIssueDropdown } from '../has_new_issue_dropdown_mixin';
import EmptyStateWithAnyIssues from './empty_state_with_any_issues.vue';
import EmptyStateWithoutAnyIssues from './empty_state_without_any_issues.vue';

const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');
const EmojiToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue');
const LabelToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue');
const MilestoneToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue');
const ReleaseToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/release_token.vue');
const CrmContactToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/crm_contact_token.vue');
const CrmOrganizationToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/crm_organization_token.vue');
const DateToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/date_token.vue');

export default {
  name: 'IssuesListAppCE',
  i18n,
  issuableListTabs,
  issuableType: TYPE_ISSUE.toUpperCase(),
  ISSUES_VIEW_TYPE_KEY,
  ISSUES_GRID_VIEW_KEY,
  ISSUES_LIST_VIEW_KEY,
  components: {
    CsvImportExportButtons,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    EmptyStateWithAnyIssues,
    EmptyStateWithoutAnyIssues,
    GlButton,
    GlButtonGroup,
    IssuableByEmail,
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
    NewResourceDropdown,
    LocalStorageSync,
    WorkItemDrawer,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin(), hasNewIssueDropdown()],
  provide: {
    [INJECTION_LINK_CHILD_PREVENT_ROUTER_NAVIGATION]: true,
  },
  inject: [
    'autocompleteAwardEmojisPath',
    'calendarPath',
    'canBulkUpdate',
    'canCreateIssue',
    'canReadCrmContact',
    'canReadCrmOrganization',
    'exportCsvPath',
    'fullPath',
    'hasAnyIssues',
    'hasAnyProjects',
    'hasBlockedIssuesFeature',
    'hasIssuableHealthStatusFeature',
    'hasIssueDateFilterFeature',
    'hasIssueWeightsFeature',
    'hasOkrsFeature',
    'hasQualityManagementFeature',
    'hasScopedLabelsFeature',
    'initialEmail',
    'initialSort',
    'isIssueRepositioningDisabled',
    'isProject',
    'isPublicVisibilityRestricted',
    'isSignedIn',
    'newIssuePath',
    'releasesPath',
    'rssPath',
    'showNewIssueLink',
    'groupId',
    'commentTemplatePaths',
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
      exportCsvPathWithQuery: this.getExportCsvPathWithQuery(),
      filterTokens: [],
      issues: [],
      issuesCounts: {},
      issuesError: null,
      pageInfo: {},
      pageParams: {},
      showBulkEditSidebar: false,
      sortKey: CREATED_DESC,
      state: STATUS_OPEN,
      pageSize: DEFAULT_PAGE_SIZE,
      viewType: ISSUES_LIST_VIEW_KEY,
      subscribeDropdownOptions: {
        items: [
          {
            text: __('Subscribe to RSS feed'),
            href: this.rssPath,
            extraAttrs: { 'data-testid': 'subscribe-rss' },
          },
          {
            text: __('Subscribe to calendar'),
            href: this.calendarPath,
            extraAttrs: { 'data-testid': 'subscribe-calendar' },
          },
        ],
      },
      activeIssuable: null,
    };
  },
  apollo: {
    issues: {
      query: getIssuesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data[this.namespace]?.issues.nodes ?? [];
      },
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      nextFetchPolicy: fetchPolicies.CACHE_FIRST,
      // We need this for handling loading state when using frontend cache
      // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106004#note_1217325202 for details
      notifyOnNetworkStatusChange: true,
      result({ data }) {
        if (!data) {
          return;
        }
        this.pageInfo = data[this.namespace]?.issues.pageInfo ?? {};
        this.exportCsvPathWithQuery = this.getExportCsvPathWithQuery();
        this.checkDrawerParams();
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingIssues;
        Sentry.captureException(error);
      },
      skip() {
        return !this.hasAnyIssues || isEmpty(this.pageParams);
      },
    },
    issuesCounts: {
      query: getIssuesCountsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data[this.namespace] ?? {};
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingCounts;
        Sentry.captureException(error);
      },
      skip() {
        return !this.hasAnyIssues || isEmpty(this.pageParams);
      },
    },
  },
  computed: {
    queryVariables() {
      const isIidSearch = ISSUE_REFERENCE.test(this.searchQuery);
      return {
        fullPath: this.fullPath,
        hideUsers: this.isPublicVisibilityRestricted && !this.isSignedIn,
        iid: isIidSearch ? this.searchQuery.slice(1) : undefined,
        isProject: this.isProject,
        isSignedIn: this.isSignedIn,
        sort: this.sortKey,
        state: this.state,
        ...this.pageParams,
        ...this.apiFilterParams,
        search: isIidSearch ? undefined : this.searchQuery,
        types: this.apiFilterParams.types || this.defaultWorkItemTypes,
      };
    },
    namespace() {
      return this.isProject ? WORKSPACE_PROJECT : WORKSPACE_GROUP;
    },
    defaultWorkItemTypes() {
      return getDefaultWorkItemTypes({
        hasOkrsFeature: this.hasOkrsFeature,
        hasQualityManagementFeature: this.hasQualityManagementFeature,
      });
    },
    hasSearch() {
      return Boolean(
        this.searchQuery ||
          Object.keys(this.urlFilterParams).length ||
          this.pageParams.afterCursor ||
          this.pageParams.beforeCursor,
      );
    },
    isBulkEditButtonDisabled() {
      return this.showBulkEditSidebar || !this.issues.length;
    },
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION_ASC;
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
    },
    showCsvButtons() {
      return this.isProject && this.isSignedIn;
    },
    showIssuableByEmail() {
      return this.initialEmail && this.canCreateIssue;
    },
    showNewIssueDropdown() {
      return !this.isProject && this.hasAnyProjects;
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
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: UserToken,
          dataType: 'user',
          defaultUsers: [],
          operators: OPERATORS_IS_NOT_OR,
          fullPath: this.fullPath,
          isProject: this.isProject,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-author`,
          preloadedUsers,
          multiSelect: true,
        },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT_OR,
          fullPath: this.fullPath,
          isProject: this.isProject,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-assignee`,
          preloadedUsers,
          multiSelect: true,
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          token: MilestoneToken,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-milestone`,
          shouldSkipSort: true,
          fullPath: this.fullPath,
          isProject: this.isProject,
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
          multiSelect: true,
        },
        {
          type: TOKEN_TYPE_TYPE,
          title: TOKEN_TITLE_TYPE,
          icon: 'issues',
          token: GlFilteredSearchToken,
          options: this.typeTokenOptions,
        },
      ];

      if (this.isProject) {
        tokens.push({
          type: TOKEN_TYPE_RELEASE,
          title: TOKEN_TITLE_RELEASE,
          icon: 'rocket',
          token: ReleaseToken,
          fetchReleases: this.fetchReleases,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-release`,
        });
      }

      if (this.isSignedIn) {
        tokens.push({
          type: TOKEN_TYPE_MY_REACTION,
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          unique: true,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-my_reaction`,
        });

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

      if (this.canReadCrmContact) {
        tokens.push({
          type: TOKEN_TYPE_CONTACT,
          title: TOKEN_TITLE_CONTACT,
          icon: 'user',
          token: CrmContactToken,
          fullPath: this.fullPath,
          isProject: this.isProject,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-crm-contacts`,
          operators: OPERATORS_IS,
          unique: true,
        });
      }

      if (this.canReadCrmOrganization) {
        tokens.push({
          type: TOKEN_TYPE_ORGANIZATION,
          title: TOKEN_TITLE_ORGANIZATION,
          icon: 'users',
          token: CrmOrganizationToken,
          fullPath: this.fullPath,
          isProject: this.isProject,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-crm-organizations`,
          operators: OPERATORS_IS,
          unique: true,
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
      return this.issues.length > 0;
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
    typeTokenOptions() {
      return getTypeTokenOptions({
        hasOkrsFeature: this.hasOkrsFeature,
        hasQualityManagementFeature: this.hasQualityManagementFeature,
      });
    },
    currentTabCount() {
      return this.tabCounts[this.state] ?? 0;
    },
    urlParams() {
      const show = this.activeIssuable
        ? makeDrawerUrlParam(this.activeIssuable, this.fullPath)
        : undefined;
      const base = {
        sort: urlSortParams[this.sortKey],
        state: this.state,
        ...this.urlFilterParams,
        first_page_size: this.pageParams.firstPageSize,
        last_page_size: this.pageParams.lastPageSize,
        page_after: this.pageParams.afterCursor ?? undefined,
        page_before: this.pageParams.beforeCursor ?? undefined,
      };
      if (show) {
        return { ...base, show };
      }
      return base;
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
    gridViewFeatureEnabled() {
      return Boolean(this.glFeatures?.issuesGridView);
    },
    isGridView() {
      return this.viewType === ISSUES_GRID_VIEW_KEY;
    },
    isIssuableSelected() {
      return !isEmpty(this.activeIssuable);
    },
    issuesDrawerEnabled() {
      return this.glFeatures?.issuesListDrawer || gon.current_user_use_work_items_view;
    },
  },
  watch: {
    $route(newValue, oldValue) {
      if (newValue.fullPath !== oldValue.fullPath) {
        this.updateData(getParameterByName(PARAM_SORT));
      }
      if (newValue.query.show) {
        this.checkDrawerParams();
      } else {
        this.activeIssuable = null;
      }
    },
  },
  created() {
    this.updateData(this.initialSort);
    this.cache = {};
  },
  mounted() {
    eventHub.$on('issuables:toggleBulkEdit', this.toggleBulkEditSidebar);
  },
  beforeDestroy() {
    eventHub.$off('issuables:toggleBulkEdit', this.toggleBulkEditSidebar);
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
    fetchEmojis(search) {
      return this.fetchWithCache(this.autocompleteAwardEmojisPath, 'emojis', 'name', search);
    },
    fetchReleases(search) {
      return this.fetchWithCache(this.releasesPath, 'releases', 'tag', search);
    },
    fetchLabelsWithFetchPolicy(search, fetchPolicy = fetchPolicies.CACHE_FIRST) {
      return this.$apollo
        .query({
          query: searchLabelsQuery,
          variables: { fullPath: this.fullPath, search, isProject: this.isProject },
          fetchPolicy,
        })
        .then(({ data }) => data[this.namespace]?.labels.nodes)
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
    getExportCsvPathWithQuery() {
      return `${this.exportCsvPath}${window.location.search}`;
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
    handleUpdateLegacyBulkEdit() {
      // If "select all" checkbox was checked, wait for all checkboxes
      // to be checked before updating IssuableBulkUpdateSidebar class
      this.$nextTick(() => {
        eventHub.$emit('issuables:updateBulkEdit');
      });
    },
    async handleBulkUpdateClick() {
      if (!this.hasInitBulkEdit) {
        const bulkUpdateSidebar = await import('~/issuable');
        bulkUpdateSidebar.initBulkUpdateSidebar('issuable_');

        this.hasInitBulkEdit = true;
      }

      eventHub.$emit('issuables:enableBulkEdit');
    },
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }

      this.state = state;
      this.pageParams = getInitialPageParams(this.pageSize);

      this.$router.push({ query: this.urlParams });
    },
    handleDismissAlert() {
      this.issuesError = null;
    },
    handleFilter(tokens) {
      this.filterTokens = tokens;
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
    handleReorder({ newIndex, oldIndex }) {
      const issueToMove = this.issues[oldIndex];
      const isDragDropDownwards = newIndex > oldIndex;
      const isMovingToBeginning = newIndex === 0;
      const isMovingToEnd = newIndex === this.issues.length - 1;

      let moveBeforeId;
      let moveAfterId;

      if (isDragDropDownwards) {
        const afterIndex = isMovingToEnd ? newIndex : newIndex + 1;
        moveBeforeId = this.issues[newIndex].id;
        moveAfterId = this.issues[afterIndex].id;
      } else {
        const beforeIndex = isMovingToBeginning ? newIndex : newIndex - 1;
        moveBeforeId = this.issues[beforeIndex].id;
        moveAfterId = this.issues[newIndex].id;
      }

      return axios
        .put(joinPaths(issueToMove.webPath, 'reorder'), {
          move_before_id: isMovingToBeginning ? null : getIdFromGraphQLId(moveBeforeId),
          move_after_id: isMovingToEnd ? null : getIdFromGraphQLId(moveAfterId),
        })
        .then(() => {
          const serializedVariables = JSON.stringify(this.queryVariables);
          return this.$apollo.mutate({
            mutation: reorderIssuesMutation,
            variables: { oldIndex, newIndex, namespace: this.namespace, serializedVariables },
          });
        })
        .catch((error) => {
          this.issuesError = __('An error occurred while reordering issues.');
          Sentry.captureException(error);
        });
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
    showIssueRepositioningMessage() {
      createAlert({
        message: this.$options.i18n.issueRepositioningMessage,
        variant: VARIANT_INFO,
      });
    },
    toggleBulkEditSidebar(showBulkEditSidebar) {
      this.showBulkEditSidebar = showBulkEditSidebar;
    },
    handlePageSizeChange(pageSize) {
      this.pageSize = pageSize;
      this.pageParams = getInitialPageParams(pageSize);
      scrollUp();

      this.$router.push({ query: this.urlParams });
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

      const tokens = getFilterTokens(window.location.search);
      this.filterTokens = groupMultiSelectFilterTokens(tokens, this.searchTokens);

      this.exportCsvPathWithQuery = this.getExportCsvPathWithQuery();
      this.pageParams = getInitialPageParams(
        this.pageSize,
        isPositiveInteger(firstPageSize) ? parseInt(firstPageSize, 10) : undefined,
        isPositiveInteger(lastPageSize) ? parseInt(lastPageSize, 10) : undefined,
        getParameterByName(PARAM_PAGE_AFTER) ?? undefined,
        getParameterByName(PARAM_PAGE_BEFORE) ?? undefined,
      );
      this.sortKey = sortKey;
      this.state = state || STATUS_OPEN;
    },
    switchViewType(type) {
      // Filter the wrong data from localStorage
      if (type === ISSUES_GRID_VIEW_KEY) {
        this.viewType = ISSUES_GRID_VIEW_KEY;
        return;
      }
      // The default view is list view
      this.viewType = ISSUES_LIST_VIEW_KEY;
    },
    handleSelectIssuable(issuable) {
      this.activeIssuable = {
        ...issuable,
      };
    },
    updateIssuablesCache(workItem) {
      const client = this.$apollo.provider.clients.defaultClient;
      const issuesList = client.readQuery({
        query: getIssuesQuery,
        variables: this.queryVariables,
      });

      const activeIssuable = issuesList[this.namespace].issues.nodes.find(
        (issue) => getIdFromGraphQLId(issue.id) === getIdFromGraphQLId(workItem.id),
      );

      if (!activeIssuable) {
        return;
      }

      // when we change issuable state, it's moved to a different tab
      // to ensure that we show 20 items of the first page, we need to refetch issuables
      if (!activeIssuable.state.includes(workItem.state.toLowerCase())) {
        this.refetchIssuables();
        return;
      }

      // handle all other widgets
      const data = mapWorkItemWidgetsToIssuableFields({
        list: issuesList,
        workItem,
        namespace: this.namespace,
        type: 'issue',
      });

      client.writeQuery({ query: getIssuesQuery, variables: this.queryVariables, data });
    },
    promoteToObjective(workItemIid) {
      const { cache } = this.$apollo.provider.clients.defaultClient;

      cache.updateQuery({ query: getIssuesQuery, variables: this.queryVariables }, (issuesList) =>
        produce(issuesList, (draftData) => {
          const activeItem = draftData[this.namespace].issues.nodes.find(
            (issue) => issue.iid === workItemIid,
          );

          activeItem.type = WORK_ITEM_TYPE_ENUM_OBJECTIVE;
        }),
      );
    },
    refetchIssuables() {
      this.$apollo.queries.issues.refetch();
      this.$apollo.queries.issuesCounts.refetch();
    },
    deleteIssuable() {
      this.activeIssuable = null;
      this.refetchIssuables();
    },
    updateIssuableEmojis(workItem) {
      const client = this.$apollo.provider.clients.defaultClient;
      const issuesList = client.readQuery({
        query: getIssuesQuery,
        variables: this.queryVariables,
      });

      const data = updateUpvotesCount({ list: issuesList, workItem, namespace: this.namespace });

      client.writeQuery({ query: getIssuesQuery, variables: this.queryVariables, data });
    },
    checkDrawerParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (this.activeIssuable || !queryParam) {
        return;
      }

      const params = JSON.parse(atob(queryParam));
      if (params.id) {
        const issue = this.issues.find((i) => getIdFromGraphQLId(i.id) === params.id);
        if (issue) {
          this.activeIssuable = {
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
  },
};
</script>

<template>
  <div>
    <work-item-drawer
      v-if="issuesDrawerEnabled"
      :open="isIssuableSelected"
      :active-item="activeIssuable"
      :issuable-type="$options.issuableType"
      :new-comment-template-paths="commentTemplatePaths"
      click-outside-exclude-selector=".issuable-list"
      @close="activeIssuable = null"
      @work-item-updated="updateIssuablesCache"
      @work-item-emoji-updated="updateIssuableEmojis"
      @addChild="refetchIssuables"
      @deleteWorkItemError="issuesError = __('An error occurred while deleting an issuable.')"
      @workItemDeleted="deleteIssuable"
      @promotedToObjective="promoteToObjective"
      @workItemTypeChanged="updateIssuablesCache($event)"
    />
    <issuable-list
      v-if="hasAnyIssues"
      :namespace="fullPath"
      :full-path="fullPath"
      recent-searches-storage-key="issues"
      :search-tokens="searchTokens"
      :has-scoped-labels-feature="hasScopedLabelsFeature"
      :initial-filter-value="filterTokens"
      :sort-options="sortOptions"
      :initial-sort-by="sortKey"
      :issuables="issues"
      :error="issuesError"
      label-filter-param="label_name"
      :tabs="$options.issuableListTabs"
      :current-tab="state"
      :tab-counts="tabCounts"
      :truncate-counts="!isProject"
      :issuables-loading="isLoading"
      :is-manual-ordering="isManualOrdering"
      :show-bulk-edit-sidebar="showBulkEditSidebar"
      :show-pagination-controls="showPaginationControls"
      :default-page-size="pageSize"
      show-filtered-search-friendly-text
      sync-filter-and-sort
      use-keyset-pagination
      :show-page-size-selector="showPageSizeSelector"
      :has-next-page="pageInfo.hasNextPage"
      :has-previous-page="pageInfo.hasPreviousPage"
      :is-grid-view="isGridView"
      :active-issuable="activeIssuable"
      show-work-item-type-icon
      :prevent-redirect="issuesDrawerEnabled"
      @click-tab="handleClickTab"
      @dismiss-alert="handleDismissAlert"
      @filter="handleFilter"
      @next-page="handleNextPage"
      @previous-page="handlePreviousPage"
      @reorder="handleReorder"
      @sort="handleSort"
      @update-legacy-bulk-edit="handleUpdateLegacyBulkEdit"
      @page-size-change="handlePageSizeChange"
      @select-issuable="handleSelectIssuable"
    >
      <template #nav-actions>
        <div class="gl-flex gl-gap-3">
          <local-storage-sync
            v-if="gridViewFeatureEnabled"
            :value="viewType"
            :storage-key="$options.ISSUES_VIEW_TYPE_KEY"
            @input="switchViewType"
          >
            <gl-button-group>
              <gl-button
                :variant="isGridView ? 'default' : 'confirm'"
                data-testid="list-view-type"
                @click="switchViewType($options.ISSUES_LIST_VIEW_KEY)"
              >
                {{ __('List') }}
              </gl-button>
              <gl-button
                :variant="isGridView ? 'confirm' : 'default'"
                data-testid="grid-view-type"
                @click="switchViewType($options.ISSUES_GRID_VIEW_KEY)"
              >
                {{ __('Grid') }}
              </gl-button>
            </gl-button-group>
          </local-storage-sync>

          <gl-button
            v-if="canBulkUpdate"
            :disabled="isBulkEditButtonDisabled"
            class="gl-shrink-0 gl-grow"
            @click="handleBulkUpdateClick"
          >
            {{ __('Bulk edit') }}
          </gl-button>
          <slot name="new-issuable-button">
            <gl-button
              v-if="showNewIssueLink"
              :href="newIssuePath"
              variant="confirm"
              class="gl-grow"
            >
              {{ __('New issue') }}
            </gl-button>
          </slot>
          <new-resource-dropdown
            v-if="showNewIssueDropdown"
            :query="$options.searchProjectsQuery"
            :query-variables="newIssueDropdownQueryVariables"
            :extract-projects="extractProjects"
            :group-id="groupId"
          />
          <gl-disclosure-dropdown
            v-gl-tooltip.hover="$options.i18n.actionsLabel"
            category="tertiary"
            icon="ellipsis_v"
            no-caret
            :toggle-text="$options.i18n.actionsLabel"
            text-sr-only
            data-testid="issues-list-more-actions-dropdown"
            toggle-class="!gl-m-0 gl-h-full"
            class="!gl-w-7"
          >
            <csv-import-export-buttons
              v-if="showCsvButtons"
              :export-csv-path="exportCsvPathWithQuery"
              :issuable-count="currentTabCount"
            />
            <gl-disclosure-dropdown-group
              :bordered="showCsvButtons"
              :group="subscribeDropdownOptions"
            />
          </gl-disclosure-dropdown>
        </div>
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
        <empty-state-with-any-issues :has-search="hasSearch" :is-open-tab="isOpenTab" />
      </template>

      <template #list-body>
        <slot name="list-body"></slot>
      </template>

      <template #title-icons="{ issuable }">
        <slot name="title-icons" v-bind="{ issuable, apiFilterParams }"></slot>
      </template>
    </issuable-list>

    <empty-state-without-any-issues
      v-else
      :current-tab-count="currentTabCount"
      :export-csv-path-with-query="exportCsvPathWithQuery"
      :show-csv-buttons="showCsvButtons"
      :show-new-issue-dropdown="showNewIssueDropdown"
    />

    <issuable-by-email
      v-if="showIssuableByEmail"
      class="gl-pb-7 gl-pt-5 gl-text-center"
      data-track-action="click_email_issue_project_issues_empty_list_page"
      data-track-label="email_issue_project_issues_empty_list"
    />
  </div>
</template>
