<script>
import {
  GlButton,
  GlFilteredSearchToken,
  GlTooltipDirective,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { isEmpty } from 'lodash';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import getIssuesCountsQuery from 'ee_else_ce/issues/list/queries/get_issues_counts.query.graphql';
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
} from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import { fetchPolicies } from '~/lib/graphql';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName, joinPaths } from '~/lib/utils/url_utility';
import {
  OPERATORS_IS,
  OPERATORS_IS_NOT,
  OPERATORS_IS_NOT_OR,
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
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { DEFAULT_PAGE_SIZE, issuableListTabs } from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import {
  CREATED_DESC,
  defaultTypeTokenOptions,
  defaultWorkItemTypes,
  i18n,
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
} from '../constants';
import eventHub from '../eventhub';
import reorderIssuesMutation from '../queries/reorder_issues.mutation.graphql';
import searchLabelsQuery from '../queries/search_labels.query.graphql';
import searchMilestonesQuery from '../queries/search_milestones.query.graphql';
import searchUsersQuery from '../queries/search_users.query.graphql';
import setSortPreferenceMutation from '../queries/set_sort_preference.mutation.graphql';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  getFilterTokens,
  getInitialPageParams,
  getSortKey,
  getSortOptions,
  isSortKey,
} from '../utils';
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

export default {
  i18n,
  issuableListTabs,
  components: {
    CsvImportExportButtons,
    EmptyStateWithAnyIssues,
    EmptyStateWithoutAnyIssues,
    GlButton,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    IssuableByEmail,
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
    NewResourceDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin(), hasNewIssueDropdown()],
  inject: [
    'autocompleteAwardEmojisPath',
    'calendarPath',
    'canBulkUpdate',
    'canReadCrmContact',
    'canReadCrmOrganization',
    'exportCsvPath',
    'fullPath',
    'hasAnyIssues',
    'hasAnyProjects',
    'hasBlockedIssuesFeature',
    'hasIssuableHealthStatusFeature',
    'hasIssueWeightsFeature',
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
  ],
  props: {
    eeSearchTokens: {
      type: Array,
      required: false,
      default: () => [],
    },
    eeTypeTokenOptions: {
      type: Array,
      required: false,
      default: () => [],
    },
    eeWorkItemTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
    eeIsOkrsEnabled: {
      type: Boolean,
      required: false,
      default: false,
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
      // We need this for handling loading state when using frontend cache
      // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106004#note_1217325202 for details
      notifyOnNetworkStatusChange: true,
      result({ data }) {
        if (!data) {
          return;
        }
        this.pageInfo = data[this.namespace]?.issues.pageInfo ?? {};
        this.exportCsvPathWithQuery = this.getExportCsvPathWithQuery();
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
      context: {
        isSingleRequest: true,
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
        search: isIidSearch ? undefined : this.searchQuery,
        sort: this.sortKey,
        state: this.state,
        ...this.pageParams,
        ...this.apiFilterParams,
        types: this.apiFilterParams.types || this.defaultWorkItemTypes,
      };
    },
    namespace() {
      return this.isProject ? WORKSPACE_PROJECT : WORKSPACE_GROUP;
    },
    defaultWorkItemTypes() {
      return [...defaultWorkItemTypes, ...this.eeWorkItemTypes];
    },
    typeTokenOptions() {
      return [...defaultTypeTokenOptions, ...this.eeTypeTokenOptions];
    },
    hasOrFeature() {
      return this.glFeatures.orIssuableQueries;
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
      return this.initialEmail && this.isSignedIn;
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
          defaultUsers: [],
          operators: this.hasOrFeature ? OPERATORS_IS_NOT_OR : OPERATORS_IS_NOT,
          fetchUsers: this.fetchUsers,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-author`,
          preloadedUsers,
        },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: UserToken,
          operators: this.hasOrFeature ? OPERATORS_IS_NOT_OR : OPERATORS_IS_NOT,
          fetchUsers: this.fetchUsers,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-assignee`,
          preloadedUsers,
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'clock',
          token: MilestoneToken,
          fetchMilestones: this.fetchMilestones,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-milestone`,
          shouldSkipSort: true,
        },
        {
          type: TOKEN_TYPE_LABEL,
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
          operators: this.hasOrFeature ? OPERATORS_IS_NOT_OR : OPERATORS_IS_NOT,
          fetchLabels: this.fetchLabels,
          fetchLatestLabels: this.glFeatures.frontendCaching ? this.fetchLatestLabels : null,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-label`,
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
      return this.issues.length > 0 && (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage);
    },
    showPageSizeControls() {
      return this.currentTabCount > DEFAULT_PAGE_SIZE;
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
    currentTabCount() {
      return this.tabCounts[this.state] ?? 0;
    },
    urlParams() {
      return {
        search: this.searchQuery,
        sort: urlSortParams[this.sortKey],
        state: this.state,
        ...this.urlFilterParams,
        first_page_size: this.pageParams.firstPageSize,
        last_page_size: this.pageParams.lastPageSize,
        page_after: this.pageParams.afterCursor ?? undefined,
        page_before: this.pageParams.beforeCursor ?? undefined,
      };
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
  mounted() {
    eventHub.$on('issuables:toggleBulkEdit', this.toggleBulkEditSidebar);
  },
  beforeDestroy() {
    eventHub.$off('issuables:toggleBulkEdit', this.toggleBulkEditSidebar);
  },
  methods: {
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
    fetchMilestones(search) {
      return this.$apollo
        .query({
          query: searchMilestonesQuery,
          variables: { fullPath: this.fullPath, search, isProject: this.isProject },
        })
        .then(({ data }) => data[this.namespace]?.milestones.nodes);
    },
    fetchUsers(search) {
      return this.$apollo
        .query({
          query: searchUsersQuery,
          variables: { fullPath: this.fullPath, search, isProject: this.isProject },
        })
        .then(({ data }) =>
          data[this.namespace]?.[`${this.namespace}Members`].nodes.map((member) => member.user),
        );
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
          this.issuesError = this.$options.i18n.reorderError;
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
    handlePageSizeChange(newPageSize) {
      const pageParam = getParameterByName(PARAM_LAST_PAGE_SIZE) ? 'lastPageSize' : 'firstPageSize';
      this.pageParams[pageParam] = newPageSize;
      this.pageSize = newPageSize;
      scrollUp();

      this.$router.push({ query: this.urlParams });
    },
    updateData(sortValue) {
      const firstPageSize = getParameterByName(PARAM_FIRST_PAGE_SIZE);
      const lastPageSize = getParameterByName(PARAM_LAST_PAGE_SIZE);
      const state = getParameterByName(PARAM_STATE);

      const defaultSortKey = state === STATUS_CLOSED ? UPDATED_DESC : CREATED_DESC;
      const dashboardSortKey = getSortKey(sortValue);
      const graphQLSortKey = isSortKey(sortValue?.toUpperCase()) && sortValue.toUpperCase();

      // The initial sort is an old enum value when it is saved on the Haml dashboard issues page.
      // The initial sort is a GraphQL enum value when it is saved on the Vue group/project issues page.
      let sortKey = dashboardSortKey || graphQLSortKey || defaultSortKey;

      if (this.isIssueRepositioningDisabled && sortKey === RELATIVE_POSITION_ASC) {
        this.showIssueRepositioningMessage();
        sortKey = defaultSortKey;
      }

      this.filterTokens = getFilterTokens(window.location.search);

      this.exportCsvPathWithQuery = this.getExportCsvPathWithQuery();
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
  },
};
</script>

<template>
  <div>
    <issuable-list
      v-if="hasAnyIssues"
      :namespace="fullPath"
      recent-searches-storage-key="issues"
      :search-input-placeholder="$options.i18n.searchPlaceholder"
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
      sync-filter-and-sort
      use-keyset-pagination
      :show-page-size-change-controls="showPageSizeControls"
      :has-next-page="pageInfo.hasNextPage"
      :has-previous-page="pageInfo.hasPreviousPage"
      :show-filtered-search-friendly-text="hasOrFeature"
      show-work-item-type-icon
      @click-tab="handleClickTab"
      @dismiss-alert="handleDismissAlert"
      @filter="handleFilter"
      @next-page="handleNextPage"
      @previous-page="handlePreviousPage"
      @reorder="handleReorder"
      @sort="handleSort"
      @update-legacy-bulk-edit="handleUpdateLegacyBulkEdit"
      @page-size-change="handlePageSizeChange"
    >
      <template #nav-actions>
        <gl-button
          v-if="canBulkUpdate"
          :disabled="isBulkEditButtonDisabled"
          @click="handleBulkUpdateClick"
        >
          {{ $options.i18n.editIssues }}
        </gl-button>
        <gl-button
          v-if="showNewIssueLink && !eeIsOkrsEnabled"
          :href="newIssuePath"
          variant="confirm"
        >
          {{ $options.i18n.newIssueLabel }}
        </gl-button>
        <slot name="new-objective-button"></slot>
        <new-resource-dropdown
          v-if="showNewIssueDropdown"
          :query="$options.searchProjectsQuery"
          :query-variables="newIssueDropdownQueryVariables"
          :extract-projects="extractProjects"
        />
        <gl-dropdown
          v-gl-tooltip.hover="$options.i18n.actionsLabel"
          category="tertiary"
          icon="ellipsis_v"
          no-caret
          :text="$options.i18n.actionsLabel"
          text-sr-only
          data-qa-selector="issues_list_more_actions_dropdown"
        >
          <csv-import-export-buttons
            v-if="showCsvButtons"
            :export-csv-path="exportCsvPathWithQuery"
            :issuable-count="currentTabCount"
          />

          <gl-dropdown-divider v-if="showCsvButtons" />

          <gl-dropdown-item :href="rssPath">
            {{ $options.i18n.rssLabel }}
          </gl-dropdown-item>
          <gl-dropdown-item :href="calendarPath">
            {{ $options.i18n.calendarLabel }}
          </gl-dropdown-item>
        </gl-dropdown>
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
    </issuable-list>

    <empty-state-without-any-issues
      v-else
      :current-tab-count="currentTabCount"
      :export-csv-path-with-query="exportCsvPathWithQuery"
      :show-csv-buttons="showCsvButtons"
      :show-new-issue-dropdown="showNewIssueDropdown"
    />

    <issuable-by-email v-if="showIssuableByEmail" class="gl-text-center gl-pt-5 gl-pb-7" />
  </div>
</template>
