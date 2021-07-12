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
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import getIssuesQuery from 'ee_else_ce/issues_list/queries/get_issues.query.graphql';
import createFlash from '~/flash';
import { TYPE_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/issuable_list/constants';
import {
  CREATED_DESC,
  i18n,
  initialPageParams,
  issuesCountSmartQueryBase,
  MAX_LIST_SIZE,
  PAGE_SIZE,
  PARAM_DUE_DATE,
  PARAM_SORT,
  PARAM_STATE,
  RELATIVE_POSITION_ASC,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_WEIGHT,
  UPDATED_DESC,
  urlSortParams,
} from '~/issues_list/constants';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  getDueDateValue,
  getFilterTokens,
  getSortKey,
  getSortOptions,
} from '~/issues_list/utils';
import axios from '~/lib/utils/axios_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  DEFAULT_NONE_ANY,
  OPERATOR_IS_ONLY,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_EPIC,
  TOKEN_TITLE_ITERATION,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_WEIGHT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import EpicToken from '~/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import IterationToken from '~/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import WeightToken from '~/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';
import eventHub from '../eventhub';
import searchIterationsQuery from '../queries/search_iterations.query.graphql';
import searchLabelsQuery from '../queries/search_labels.query.graphql';
import searchMilestonesQuery from '../queries/search_milestones.query.graphql';
import searchUsersQuery from '../queries/search_users.query.graphql';
import IssueCardTimeInfo from './issue_card_time_info.vue';

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
    BlockingIssuesCount: () => import('ee_component/issues/components/blocking_issues_count.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    autocompleteAwardEmojisPath: {
      default: '',
    },
    calendarPath: {
      default: '',
    },
    canBulkUpdate: {
      default: false,
    },
    emptyStateSvgPath: {
      default: '',
    },
    exportCsvPath: {
      default: '',
    },
    groupEpicsPath: {
      default: '',
    },
    hasBlockedIssuesFeature: {
      default: false,
    },
    hasIssueWeightsFeature: {
      default: false,
    },
    hasIterationsFeature: {
      default: false,
    },
    hasMultipleIssueAssigneesFeature: {
      default: false,
    },
    hasProjectIssues: {
      default: false,
    },
    initialEmail: {
      default: '',
    },
    isSignedIn: {
      default: false,
    },
    issuesPath: {
      default: '',
    },
    jiraIntegrationPath: {
      default: '',
    },
    newIssuePath: {
      default: '',
    },
    projectPath: {
      default: '',
    },
    rssPath: {
      default: '',
    },
    showNewIssueLink: {
      default: false,
    },
    signInPath: {
      default: '',
    },
  },
  data() {
    const state = getParameterByName(PARAM_STATE);
    const defaultSortKey = state === IssuableStates.Closed ? UPDATED_DESC : CREATED_DESC;

    return {
      dueDateFilter: getDueDateValue(getParameterByName(PARAM_DUE_DATE)),
      exportCsvPathWithQuery: this.getExportCsvPathWithQuery(),
      filterTokens: getFilterTokens(window.location.search),
      issues: [],
      pageInfo: {},
      pageParams: initialPageParams,
      showBulkEditSidebar: false,
      sortKey: getSortKey(getParameterByName(PARAM_SORT)) || defaultSortKey,
      state: state || IssuableStates.Opened,
    };
  },
  apollo: {
    issues: {
      query: getIssuesQuery,
      variables() {
        return this.queryVariables;
      },
      update: ({ project }) => project?.issues.nodes ?? [],
      result({ data }) {
        this.pageInfo = data.project?.issues.pageInfo ?? {};
        this.exportCsvPathWithQuery = this.getExportCsvPathWithQuery();
      },
      error(error) {
        createFlash({ message: this.$options.i18n.errorFetchingIssues, captureError: true, error });
      },
      skip() {
        return !this.hasProjectIssues;
      },
      debounce: 200,
    },
    countOpened: {
      ...issuesCountSmartQueryBase,
      variables() {
        return {
          ...this.queryVariables,
          state: IssuableStates.Opened,
        };
      },
      skip() {
        return !this.hasProjectIssues;
      },
    },
    countClosed: {
      ...issuesCountSmartQueryBase,
      variables() {
        return {
          ...this.queryVariables,
          state: IssuableStates.Closed,
        };
      },
      skip() {
        return !this.hasProjectIssues;
      },
    },
    countAll: {
      ...issuesCountSmartQueryBase,
      variables() {
        return {
          ...this.queryVariables,
          state: IssuableStates.All,
        };
      },
      skip() {
        return !this.hasProjectIssues;
      },
    },
  },
  computed: {
    queryVariables() {
      return {
        isSignedIn: this.isSignedIn,
        projectPath: this.projectPath,
        search: this.searchQuery,
        sort: this.sortKey,
        state: this.state,
        ...this.pageParams,
        ...this.apiFilterParams,
      };
    },
    hasSearch() {
      return this.searchQuery || Object.keys(this.urlFilterParams).length;
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
          operators: OPERATOR_IS_ONLY,
          fetchAuthors: this.fetchUsers,
          preloadedAuthors,
        },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: AuthorToken,
          dataType: 'user',
          unique: !this.hasMultipleIssueAssigneesFeature,
          defaultAuthors: DEFAULT_NONE_ANY,
          fetchAuthors: this.fetchUsers,
          preloadedAuthors,
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'clock',
          token: MilestoneToken,
          unique: true,
          defaultMilestones: [],
          fetchMilestones: this.fetchMilestones,
        },
        {
          type: TOKEN_TYPE_LABEL,
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
          defaultLabels: DEFAULT_NONE_ANY,
          fetchLabels: this.fetchLabels,
        },
      ];

      if (this.isSignedIn) {
        tokens.push({
          type: TOKEN_TYPE_MY_REACTION,
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          unique: true,
          operators: OPERATOR_IS_ONLY,
          fetchEmojis: this.fetchEmojis,
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

      if (this.hasIterationsFeature) {
        tokens.push({
          type: TOKEN_TYPE_ITERATION,
          title: TOKEN_TITLE_ITERATION,
          icon: 'iteration',
          token: IterationToken,
          unique: true,
          fetchIterations: this.fetchIterations,
        });
      }

      if (this.groupEpicsPath) {
        tokens.push({
          type: TOKEN_TYPE_EPIC,
          title: TOKEN_TITLE_EPIC,
          icon: 'epic',
          token: EpicToken,
          unique: true,
          idProperty: 'id',
          useIdValue: true,
          fetchEpics: this.fetchEpics,
        });
      }

      if (this.hasIssueWeightsFeature) {
        tokens.push({
          type: TOKEN_TYPE_WEIGHT,
          title: TOKEN_TITLE_WEIGHT,
          icon: 'weight',
          token: WeightToken,
          unique: true,
        });
      }

      return tokens;
    },
    showPaginationControls() {
      return this.issues.length > 0 && (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage);
    },
    sortOptions() {
      return getSortOptions(this.hasIssueWeightsFeature, this.hasBlockedIssuesFeature);
    },
    tabCounts() {
      return {
        [IssuableStates.Opened]: this.countOpened,
        [IssuableStates.Closed]: this.countClosed,
        [IssuableStates.All]: this.countAll,
      };
    },
    currentTabCount() {
      return this.tabCounts[this.state] ?? 0;
    },
    urlParams() {
      return {
        due_date: this.dueDateFilter,
        search: this.searchQuery,
        sort: urlSortParams[this.sortKey],
        state: this.state,
        ...this.urlFilterParams,
      };
    },
  },
  created() {
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
    async fetchEpics({ search }) {
      const epics = await this.fetchWithCache(this.groupEpicsPath, 'epics');
      if (!search) {
        return epics.slice(0, MAX_LIST_SIZE);
      }
      const number = Number(search);
      return Number.isNaN(number)
        ? fuzzaldrinPlus.filter(epics, search, { key: 'title' })
        : epics.filter((epic) => epic.id === number);
    },
    fetchLabels(search) {
      return this.$apollo
        .query({
          query: searchLabelsQuery,
          variables: { projectPath: this.projectPath, search },
        })
        .then(({ data }) => data.project.labels.nodes);
    },
    fetchMilestones(search) {
      return this.$apollo
        .query({
          query: searchMilestonesQuery,
          variables: { projectPath: this.projectPath, search },
        })
        .then(({ data }) => data.project.milestones.nodes);
    },
    fetchIterations(search) {
      const id = Number(search);
      const variables =
        !search || Number.isNaN(id)
          ? { projectPath: this.projectPath, search }
          : { projectPath: this.projectPath, id };

      return this.$apollo
        .query({
          query: searchIterationsQuery,
          variables,
        })
        .then(({ data }) => data.project.iterations.nodes);
    },
    fetchUsers(search) {
      return this.$apollo
        .query({
          query: searchUsersQuery,
          variables: { projectPath: this.projectPath, search },
        })
        .then(({ data }) => data.project.projectMembers.nodes.map((member) => member.user));
    },
    getExportCsvPathWithQuery() {
      return `${this.exportCsvPath}${window.location.search}`;
    },
    getStatus(issue) {
      if (issue.closedAt && issue.moved) {
        return this.$options.i18n.closedMoved;
      }
      if (issue.closedAt) {
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
        const initBulkUpdateSidebar = await import(
          '~/issuable_bulk_update_sidebar/issuable_init_bulk_update_sidebar'
        );
        initBulkUpdateSidebar.default.init('issuable_');

        const usersSelect = await import('~/users_select');
        const UsersSelect = usersSelect.default;
        new UsersSelect(); // eslint-disable-line no-new

        this.hasInitBulkEdit = true;
      }

      eventHub.$emit('issuables:enableBulkEdit');
    },
    handleClickTab(state) {
      if (this.state !== state) {
        this.pageParams = initialPageParams;
      }
      this.state = state;
    },
    handleFilter(filter) {
      this.pageParams = initialPageParams;
      this.filterTokens = filter;
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
        .put(`${this.issuesPath}/${issueToMove.iid}/reorder`, {
          move_before_id: isMovingToBeginning ? null : moveBeforeId,
          move_after_id: isMovingToEnd ? null : moveAfterId,
        })
        .then(() => {
          // Move issue to new position in list
          this.issues.splice(oldIndex, 1);
          this.issues.splice(newIndex, 0, issueToMove);
        })
        .catch(() => {
          createFlash({ message: this.$options.i18n.reorderError });
        });
    },
    handleSort(sortKey) {
      if (this.sortKey !== sortKey) {
        this.pageParams = initialPageParams;
      }
      this.sortKey = sortKey;
    },
    toggleBulkEditSidebar(showBulkEditSidebar) {
      this.showBulkEditSidebar = showBulkEditSidebar;
    },
  },
};
</script>

<template>
  <div v-if="hasProjectIssues">
    <issuable-list
      :namespace="projectPath"
      recent-searches-storage-key="issues"
      :search-input-placeholder="$options.i18n.searchPlaceholder"
      :search-tokens="searchTokens"
      :initial-filter-value="filterTokens"
      :sort-options="sortOptions"
      :initial-sort-by="sortKey"
      :issuables="issues"
      label-filter-param="label_name"
      :tabs="$options.IssuableListTabs"
      :current-tab="state"
      :tab-counts="tabCounts"
      :issuables-loading="$apollo.queries.issues.loading"
      :is-manual-ordering="isManualOrdering"
      :show-bulk-edit-sidebar="showBulkEditSidebar"
      :show-pagination-controls="showPaginationControls"
      :use-keyset-pagination="true"
      :has-next-page="pageInfo.hasNextPage"
      :has-previous-page="pageInfo.hasPreviousPage"
      :url-params="urlParams"
      @click-tab="handleClickTab"
      @filter="handleFilter"
      @next-page="handleNextPage"
      @previous-page="handlePreviousPage"
      @reorder="handleReorder"
      @sort="handleSort"
      @update-legacy-bulk-edit="handleUpdateLegacyBulkEdit"
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
          v-if="isSignedIn"
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
        <blocking-issues-count
          class="blocking-issues gl-display-none gl-sm-display-block"
          :blocking-issues-count="issuable.blockingCount"
          :is-list-item="true"
          data-testid="blocking-issues"
        />
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

    <issuable-by-email v-if="initialEmail" class="gl-text-center gl-pt-5 gl-pb-7" />
  </div>

  <div v-else-if="isSignedIn">
    <gl-empty-state
      :description="$options.i18n.noIssuesSignedInDescription"
      :title="$options.i18n.noIssuesSignedInTitle"
      :svg-path="emptyStateSvgPath"
    >
      <template #actions>
        <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
          {{ $options.i18n.newIssueLabel }}
        </gl-button>
        <csv-import-export-buttons
          class="gl-mr-3"
          :export-csv-path="exportCsvPathWithQuery"
          :issuable-count="currentTabCount"
        />
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
  </div>

  <gl-empty-state
    v-else
    :description="$options.i18n.noIssuesSignedOutDescription"
    :title="$options.i18n.noIssuesSignedOutTitle"
    :svg-path="emptyStateSvgPath"
    :primary-button-text="$options.i18n.noIssuesSignedOutButtonText"
    :primary-button-link="signInPath"
  />
</template>
