<script>
import {
  GlButton,
  GlEmptyState,
  GlFilteredSearchToken,
  GlIcon,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import getIssuesCountsQuery from 'ee_else_ce/issues/list/queries/get_issues_counts.query.graphql';
import createFlash, { FLASH_TYPES } from '~/flash';
import { TYPE_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ITEM_TYPE } from '~/groups/constants';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import { IssuableStatus } from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName, joinPaths } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  DEFAULT_NONE_ANY,
  FILTERED_SEARCH_TERM,
  OPERATOR_IS_ONLY,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_CONTACT,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_ORGANIZATION,
  TOKEN_TITLE_RELEASE,
  TOKEN_TITLE_TYPE,
  OPERATOR_IS_NOT_OR,
  OPERATOR_IS_AND_IS_NOT,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_CONTACT,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_ORGANIZATION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  CREATED_DESC,
  defaultTypeTokenOptions,
  defaultWorkItemTypes,
  i18n,
  ISSUE_REFERENCE,
  MAX_LIST_SIZE,
  PAGE_SIZE,
  PARAM_FIRST_PAGE_SIZE,
  PARAM_LAST_PAGE_SIZE,
  PARAM_PAGE_AFTER,
  PARAM_PAGE_BEFORE,
  PARAM_SORT,
  PARAM_STATE,
  RELATIVE_POSITION_ASC,
  TYPE_TOKEN_TASK_OPTION,
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
import NewIssueDropdown from './new_issue_dropdown.vue';

const AuthorToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/author_token.vue');
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
  IssuableListTabs,
  components: {
    CsvImportExportButtons,
    GlButton,
    GlEmptyState,
    GlIcon,
    GlLink,
    GlSprintf,
    IssuableByEmail,
    IssuableList,
    IssueCardTimeInfo,
    NewIssueDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'autocompleteAwardEmojisPath',
    'calendarPath',
    'canBulkUpdate',
    'canCreateProjects',
    'canReadCrmContact',
    'canReadCrmOrganization',
    'emptyStateSvgPath',
    'exportCsvPath',
    'fullPath',
    'hasAnyIssues',
    'hasAnyProjects',
    'hasBlockedIssuesFeature',
    'hasIssueWeightsFeature',
    'hasScopedLabelsFeature',
    'initialEmail',
    'initialSort',
    'isAnonymousSearchDisabled',
    'isIssueRepositioningDisabled',
    'isProject',
    'isPublicVisibilityRestricted',
    'isSignedIn',
    'jiraIntegrationPath',
    'newIssuePath',
    'newProjectPath',
    'releasesPath',
    'rssPath',
    'showNewIssueLink',
    'signInPath',
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
      state: IssuableStates.Opened,
      pageSize: PAGE_SIZE,
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
        return !this.hasAnyIssues;
      },
      debounce: 200,
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
        return !this.hasAnyIssues;
      },
      debounce: 200,
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
        types: this.apiFilterParams.types || defaultWorkItemTypes,
      };
    },
    namespace() {
      return this.isProject ? ITEM_TYPE.PROJECT : ITEM_TYPE.GROUP;
    },
    typeTokenOptions() {
      return defaultTypeTokenOptions.concat(TYPE_TOKEN_TASK_OPTION);
    },
    hasOrFeature() {
      return this.glFeatures.orIssuableQueries;
    },
    hasSearch() {
      return (
        this.searchQuery ||
        Object.keys(this.urlFilterParams).length ||
        this.pageParams.afterCursor ||
        this.pageParams.beforeCursor
      );
    },
    isBulkEditButtonDisabled() {
      return this.showBulkEditSidebar || !this.issues.length;
    },
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION_ASC;
    },
    isOpenTab() {
      return this.state === IssuableStates.Opened;
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
      return convertToSearchQuery(this.filterTokens) || undefined;
    },
    searchTokens() {
      const preloadedAuthors = [];

      if (gon.current_user_id) {
        preloadedAuthors.push({
          id: convertToGraphQLId(TYPE_USER, gon.current_user_id),
          name: gon.current_user_fullname,
          username: gon.current_username,
          avatar_url: gon.current_user_avatar_url,
        });
      }

      const tokens = [
        {
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: AuthorToken,
          dataType: 'user',
          unique: true,
          defaultAuthors: [],
          fetchAuthors: this.fetchUsers,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-author`,
          preloadedAuthors,
        },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: AuthorToken,
          dataType: 'user',
          defaultAuthors: DEFAULT_NONE_ANY,
          operators: this.hasOrFeature ? OPERATOR_IS_NOT_OR : OPERATOR_IS_AND_IS_NOT,
          fetchAuthors: this.fetchUsers,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-assignee`,
          preloadedAuthors,
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
          defaultLabels: DEFAULT_NONE_ANY,
          fetchLabels: this.fetchLabels,
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
          operators: OPERATOR_IS_ONLY,
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
          defaultContacts: DEFAULT_NONE_ANY,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-crm-contacts`,
          operators: OPERATOR_IS_ONLY,
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
          defaultOrganizations: DEFAULT_NONE_ANY,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-crm-organizations`,
          operators: OPERATOR_IS_ONLY,
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
      /** only show page size controls when the tab count is greater than the default/minimum page size control i.e 20 in this case */
      return this.currentTabCount > PAGE_SIZE;
    },
    sortOptions() {
      return getSortOptions(this.hasIssueWeightsFeature, this.hasBlockedIssuesFeature);
    },
    tabCounts() {
      const { openedIssues, closedIssues, allIssues } = this.issuesCounts;
      return {
        [IssuableStates.Opened]: openedIssues?.count,
        [IssuableStates.Closed]: closedIssues?.count,
        [IssuableStates.All]: allIssues?.count,
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
    issuesHelpPagePath() {
      return helpPagePath('user/project/issues/index');
    },
    shouldDisableSomeFilters() {
      return this.isAnonymousSearchDisabled && !this.isSignedIn;
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
    fetchWithCache(path, cacheName, searchKey, search, wrapData = false) {
      if (this.cache[cacheName]) {
        const data = search
          ? fuzzaldrinPlus.filter(this.cache[cacheName], search, { key: searchKey })
          : this.cache[cacheName].slice(0, MAX_LIST_SIZE);
        return wrapData ? Promise.resolve({ data }) : Promise.resolve(data);
      }

      return axios.get(path).then(({ data }) => {
        this.cache[cacheName] = data;
        const result = data.slice(0, MAX_LIST_SIZE);
        return wrapData ? { data: result } : result;
      });
    },
    fetchEmojis(search) {
      return this.fetchWithCache(this.autocompleteAwardEmojisPath, 'emojis', 'name', search);
    },
    fetchReleases(search) {
      return this.fetchWithCache(this.releasesPath, 'releases', 'tag', search);
    },
    fetchLabels(search) {
      return this.$apollo
        .query({
          query: searchLabelsQuery,
          variables: { fullPath: this.fullPath, search, isProject: this.isProject },
        })
        .then(({ data }) => data[this.namespace]?.labels.nodes)
        .then((labels) =>
          // TODO remove once we can search by title-only on the backend
          // https://gitlab.com/gitlab-org/gitlab/-/issues/346353
          labels.filter((label) => label.title.toLowerCase().includes(search.toLowerCase())),
        );
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
      if (issue.state === IssuableStatus.Closed && issue.moved) {
        return this.$options.i18n.closedMoved;
      }
      if (issue.state === IssuableStatus.Closed) {
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
        const bulkUpdateSidebar = await import('~/issuable/bulk_update_sidebar');
        bulkUpdateSidebar.initBulkUpdateSidebar('issuable_');
        bulkUpdateSidebar.initStatusDropdown();
        bulkUpdateSidebar.initSubscriptionsDropdown();
        bulkUpdateSidebar.initMoveIssuesButton();

        const usersSelect = await import('~/users_select');
        const UsersSelect = usersSelect.default;
        new UsersSelect(); // eslint-disable-line no-new

        this.hasInitBulkEdit = true;
      }

      eventHub.$emit('issuables:enableBulkEdit');
    },
    handleClickTab(state) {
      if (this.state !== state) {
        this.pageParams = getInitialPageParams(this.pageSize);
      }
      this.state = state;

      this.$router.push({ query: this.urlParams });
    },
    handleDismissAlert() {
      this.issuesError = null;
    },
    handleFilter(filter) {
      this.setFilterTokens(filter);

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
      if (this.isIssueRepositioningDisabled && sortKey === RELATIVE_POSITION_ASC) {
        this.showIssueRepositioningMessage();
        return;
      }

      if (this.sortKey !== sortKey) {
        this.pageParams = getInitialPageParams(this.pageSize);
      }
      this.sortKey = sortKey;

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
    setFilterTokens(filtersArg) {
      const filters = this.removeDisabledSearchTerms(filtersArg);

      this.filterTokens = filters;

      // If we filtered something out, let's show a warning message
      if (filters.length < filtersArg.length) {
        this.showAnonymousSearchingMessage();
      }
    },
    removeDisabledSearchTerms(filters) {
      // If we shouldn't disable anything, let's return the same thing
      if (!this.shouldDisableSomeFilters) {
        return filters;
      }

      const filtersWithoutSearchTerms = filters.filter(
        (token) => !(token.type === FILTERED_SEARCH_TERM && token.value?.data),
      );

      return filtersWithoutSearchTerms;
    },
    showAnonymousSearchingMessage() {
      createFlash({
        message: this.$options.i18n.anonymousSearchingMessage,
        type: FLASH_TYPES.NOTICE,
      });
    },
    showIssueRepositioningMessage() {
      createFlash({
        message: this.$options.i18n.issueRepositioningMessage,
        type: FLASH_TYPES.NOTICE,
      });
    },
    toggleBulkEditSidebar(showBulkEditSidebar) {
      this.showBulkEditSidebar = showBulkEditSidebar;
    },
    handlePageSizeChange(newPageSize) {
      /** make sure the page number is preserved so that the current context is not lost* */
      const lastPageSize = getParameterByName(PARAM_LAST_PAGE_SIZE);
      const pageNumberSize = lastPageSize ? 'lastPageSize' : 'firstPageSize';
      /** depending upon what page or page size we are dynamically set pageParams * */
      this.pageParams[pageNumberSize] = newPageSize;
      this.pageSize = newPageSize;
      scrollUp();

      this.$router.push({ query: this.urlParams });
    },
    updateData(sortValue) {
      const firstPageSize = getParameterByName(PARAM_FIRST_PAGE_SIZE);
      const lastPageSize = getParameterByName(PARAM_LAST_PAGE_SIZE);
      const pageAfter = getParameterByName(PARAM_PAGE_AFTER);
      const pageBefore = getParameterByName(PARAM_PAGE_BEFORE);
      const state = getParameterByName(PARAM_STATE);

      const defaultSortKey = state === IssuableStates.Closed ? UPDATED_DESC : CREATED_DESC;
      const dashboardSortKey = getSortKey(sortValue);
      const graphQLSortKey = isSortKey(sortValue?.toUpperCase()) && sortValue.toUpperCase();

      // The initial sort is an old enum value when it is saved on the dashboard issues page.
      // The initial sort is a GraphQL enum value when it is saved on the Vue issues list page.
      let sortKey = dashboardSortKey || graphQLSortKey || defaultSortKey;

      if (this.isIssueRepositioningDisabled && sortKey === RELATIVE_POSITION_ASC) {
        this.showIssueRepositioningMessage();
        sortKey = defaultSortKey;
      }

      this.exportCsvPathWithQuery = this.getExportCsvPathWithQuery();
      this.setFilterTokens(getFilterTokens(window.location.search));

      this.pageParams = getInitialPageParams(
        this.pageSize,
        isPositiveInteger(firstPageSize) ? parseInt(firstPageSize, 10) : undefined,
        isPositiveInteger(lastPageSize) ? parseInt(lastPageSize, 10) : undefined,
        pageAfter,
        pageBefore,
      );
      this.sortKey = sortKey;
      this.state = state || IssuableStates.Opened;
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
      :tabs="$options.IssuableListTabs"
      :current-tab="state"
      :tab-counts="tabCounts"
      :truncate-counts="!isProject"
      :issuables-loading="$apollo.queries.issues.loading"
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
          v-gl-tooltip
          :href="rssPath"
          icon="rss"
          :title="$options.i18n.rssLabel"
          :aria-label="$options.i18n.rssLabel"
        />
        <gl-button
          v-gl-tooltip
          :href="calendarPath"
          icon="calendar"
          :title="$options.i18n.calendarLabel"
          :aria-label="$options.i18n.calendarLabel"
        />
        <csv-import-export-buttons
          v-if="showCsvButtons"
          class="gl-md-mr-3"
          :export-csv-path="exportCsvPathWithQuery"
          :issuable-count="currentTabCount"
        />
        <gl-button
          v-if="canBulkUpdate"
          :disabled="isBulkEditButtonDisabled"
          @click="handleBulkUpdateClick"
        >
          {{ $options.i18n.editIssues }}
        </gl-button>
        <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
          {{ $options.i18n.newIssueLabel }}
        </gl-button>
        <new-issue-dropdown v-if="showNewIssueDropdown" />
      </template>

      <template #timeframe="{ issuable = {} }">
        <issue-card-time-info :issue="issuable" />
      </template>

      <template #status="{ issuable = {} }">
        {{ getStatus(issuable) }}
      </template>

      <template #statistics="{ issuable = {} }">
        <li
          v-if="issuable.mergeRequestsCount"
          v-gl-tooltip
          class="gl-display-none gl-sm-display-block"
          :title="$options.i18n.relatedMergeRequests"
          data-testid="merge-requests"
        >
          <gl-icon name="merge-request" />
          {{ issuable.mergeRequestsCount }}
        </li>
        <li
          v-if="issuable.upvotes"
          v-gl-tooltip
          class="issuable-upvotes gl-display-none gl-sm-display-block"
          :title="$options.i18n.upvotes"
          data-testid="issuable-upvotes"
        >
          <gl-icon name="thumb-up" />
          {{ issuable.upvotes }}
        </li>
        <li
          v-if="issuable.downvotes"
          v-gl-tooltip
          class="issuable-downvotes gl-display-none gl-sm-display-block"
          :title="$options.i18n.downvotes"
          data-testid="issuable-downvotes"
        >
          <gl-icon name="thumb-down" />
          {{ issuable.downvotes }}
        </li>
        <slot :issuable="issuable"></slot>
      </template>

      <template #empty-state>
        <gl-empty-state
          v-if="hasSearch"
          :description="$options.i18n.noSearchResultsDescription"
          :title="$options.i18n.noSearchResultsTitle"
          :svg-path="emptyStateSvgPath"
        >
          <template #actions>
            <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
              {{ $options.i18n.newIssueLabel }}
            </gl-button>
          </template>
        </gl-empty-state>

        <gl-empty-state
          v-else-if="isOpenTab"
          :description="$options.i18n.noOpenIssuesDescription"
          :title="$options.i18n.noOpenIssuesTitle"
          :svg-path="emptyStateSvgPath"
        >
          <template #actions>
            <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
              {{ $options.i18n.newIssueLabel }}
            </gl-button>
          </template>
        </gl-empty-state>

        <gl-empty-state
          v-else
          :title="$options.i18n.noClosedIssuesTitle"
          :svg-path="emptyStateSvgPath"
        />
      </template>
    </issuable-list>

    <template v-else-if="isSignedIn">
      <gl-empty-state :title="$options.i18n.noIssuesSignedInTitle" :svg-path="emptyStateSvgPath">
        <template #description>
          <gl-link :href="issuesHelpPagePath" target="_blank">{{
            $options.i18n.noIssuesSignedInDescription
          }}</gl-link>
          <p v-if="canCreateProjects">
            <strong>{{ $options.i18n.noGroupIssuesSignedInDescription }}</strong>
          </p>
        </template>
        <template #actions>
          <gl-button v-if="canCreateProjects" :href="newProjectPath" variant="confirm">
            {{ $options.i18n.newProjectLabel }}
          </gl-button>
          <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
            {{ $options.i18n.newIssueLabel }}
          </gl-button>
          <csv-import-export-buttons
            v-if="showCsvButtons"
            class="gl-w-full gl-sm-w-auto gl-sm-mr-3"
            :export-csv-path="exportCsvPathWithQuery"
            :issuable-count="currentTabCount"
          />
          <new-issue-dropdown v-if="showNewIssueDropdown" class="gl-align-self-center" />
        </template>
      </gl-empty-state>
      <hr />
      <p class="gl-text-center gl-font-weight-bold gl-mb-0">
        {{ $options.i18n.jiraIntegrationTitle }}
      </p>
      <p class="gl-text-center gl-mb-0">
        <gl-sprintf :message="$options.i18n.jiraIntegrationMessage">
          <template #jiraDocsLink="{ content }">
            <gl-link :href="jiraIntegrationPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <p class="gl-text-center gl-text-gray-500">
        {{ $options.i18n.jiraIntegrationSecondaryMessage }}
      </p>
    </template>

    <gl-empty-state
      v-else
      :title="$options.i18n.noIssuesSignedOutTitle"
      :svg-path="emptyStateSvgPath"
      :primary-button-text="$options.i18n.noIssuesSignedOutButtonText"
      :primary-button-link="signInPath"
    >
      <template #description>
        <gl-link :href="issuesHelpPagePath" target="_blank">{{
          $options.i18n.noIssuesSignedOutDescription
        }}</gl-link>
      </template>
    </gl-empty-state>

    <issuable-by-email v-if="showIssuableByEmail" class="gl-text-center gl-pt-5 gl-pb-7" />
  </div>
</template>
