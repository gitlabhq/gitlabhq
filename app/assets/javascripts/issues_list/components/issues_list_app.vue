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
import { toNumber } from 'lodash';
import createFlash from '~/flash';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/issuable_list/constants';
import {
  API_PARAM,
  apiSortParams,
  CREATED_DESC,
  i18n,
  MAX_LIST_SIZE,
  PAGE_SIZE,
  PARAM_DUE_DATE,
  PARAM_PAGE,
  PARAM_SORT,
  PARAM_STATE,
  RELATIVE_POSITION_DESC,
  UPDATED_DESC,
  URL_PARAM,
  urlSortParams,
} from '~/issues_list/constants';
import {
  convertToParams,
  convertToSearchQuery,
  getDueDateValue,
  getFilterTokens,
  getSortKey,
  getSortOptions,
} from '~/issues_list/utils';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase, getParameterByName } from '~/lib/utils/common_utils';
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
    autocompleteUsersPath: {
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
    endpoint: {
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
    hasIssues: {
      default: false,
    },
    hasIssueWeightsFeature: {
      default: false,
    },
    hasMultipleIssueAssigneesFeature: {
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
    projectIterationsPath: {
      default: '',
    },
    projectLabelsPath: {
      default: '',
    },
    projectMilestonesPath: {
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
      isLoading: false,
      issues: [],
      page: toNumber(getParameterByName(PARAM_PAGE)) || 1,
      showBulkEditSidebar: false,
      sortKey: getSortKey(getParameterByName(PARAM_SORT)) || defaultSortKey,
      state: state || IssuableStates.Opened,
      totalIssues: 0,
    };
  },
  computed: {
    isBulkEditButtonDisabled() {
      return this.showBulkEditSidebar || !this.issues.length;
    },
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION_DESC;
    },
    isOpenTab() {
      return this.state === IssuableStates.Opened;
    },
    apiFilterParams() {
      return convertToParams(this.filterTokens, API_PARAM);
    },
    urlFilterParams() {
      return convertToParams(this.filterTokens, URL_PARAM);
    },
    searchQuery() {
      return convertToSearchQuery(this.filterTokens) || undefined;
    },
    searchTokens() {
      const tokens = [
        {
          type: 'author_username',
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          token: AuthorToken,
          dataType: 'user',
          unique: true,
          defaultAuthors: [],
          fetchAuthors: this.fetchUsers,
        },
        {
          type: 'assignee_username',
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: AuthorToken,
          dataType: 'user',
          unique: !this.hasMultipleIssueAssigneesFeature,
          defaultAuthors: DEFAULT_NONE_ANY,
          fetchAuthors: this.fetchUsers,
        },
        {
          type: 'milestone',
          title: TOKEN_TITLE_MILESTONE,
          icon: 'clock',
          token: MilestoneToken,
          unique: true,
          defaultMilestones: [],
          fetchMilestones: this.fetchMilestones,
        },
        {
          type: 'labels',
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
          defaultLabels: [],
          fetchLabels: this.fetchLabels,
        },
        {
          type: 'my_reaction_emoji',
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          unique: true,
          operators: OPERATOR_IS_ONLY,
          fetchEmojis: this.fetchEmojis,
        },
        {
          type: 'confidential',
          title: TOKEN_TITLE_CONFIDENTIAL,
          icon: 'eye-slash',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATOR_IS_ONLY,
          options: [
            { icon: 'eye-slash', value: 'yes', title: this.$options.i18n.confidentialYes },
            { icon: 'eye', value: 'no', title: this.$options.i18n.confidentialNo },
          ],
        },
      ];

      if (this.projectIterationsPath) {
        tokens.push({
          type: 'iteration',
          title: TOKEN_TITLE_ITERATION,
          icon: 'iteration',
          token: IterationToken,
          unique: true,
          fetchIterations: this.fetchIterations,
        });
      }

      if (this.groupEpicsPath) {
        tokens.push({
          type: 'epic_id',
          title: TOKEN_TITLE_EPIC,
          icon: 'epic',
          token: EpicToken,
          unique: true,
          fetchEpics: this.fetchEpics,
        });
      }

      if (this.hasIssueWeightsFeature) {
        tokens.push({
          type: 'weight',
          title: TOKEN_TITLE_WEIGHT,
          icon: 'weight',
          token: WeightToken,
          unique: true,
        });
      }

      return tokens;
    },
    showPaginationControls() {
      return this.issues.length > 0;
    },
    sortOptions() {
      return getSortOptions(this.hasIssueWeightsFeature, this.hasBlockedIssuesFeature);
    },
    tabCounts() {
      return Object.values(IssuableStates).reduce(
        (acc, state) => ({
          ...acc,
          [state]: this.state === state ? this.totalIssues : undefined,
        }),
        {},
      );
    },
    urlParams() {
      return {
        due_date: this.dueDateFilter,
        page: this.page,
        search: this.searchQuery,
        state: this.state,
        ...urlSortParams[this.sortKey],
        ...this.urlFilterParams,
      };
    },
  },
  created() {
    this.cache = {};
  },
  mounted() {
    eventHub.$on('issuables:toggleBulkEdit', this.toggleBulkEditSidebar);
    this.fetchIssues();
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
    async fetchEpics(search) {
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
      return this.fetchWithCache(this.projectLabelsPath, 'labels', 'title', search);
    },
    fetchMilestones(search) {
      return this.fetchWithCache(this.projectMilestonesPath, 'milestones', 'title', search, true);
    },
    fetchIterations(search) {
      return axios.get(this.projectIterationsPath, { params: { search } });
    },
    fetchUsers(search) {
      return axios.get(this.autocompleteUsersPath, { params: { search } });
    },
    fetchIssues() {
      if (!this.hasIssues) {
        return undefined;
      }

      this.isLoading = true;

      return axios
        .get(this.endpoint, {
          params: {
            due_date: this.dueDateFilter,
            page: this.page,
            per_page: PAGE_SIZE,
            search: this.searchQuery,
            state: this.state,
            with_labels_details: true,
            ...apiSortParams[this.sortKey],
            ...this.apiFilterParams,
          },
        })
        .then(({ data, headers }) => {
          this.page = Number(headers['x-page']);
          this.totalIssues = Number(headers['x-total']);
          this.issues = data.map((issue) => convertObjectPropsToCamelCase(issue, { deep: true }));
          this.exportCsvPathWithQuery = this.getExportCsvPathWithQuery();
        })
        .catch(() => {
          createFlash({ message: this.$options.i18n.errorFetchingIssues });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    getExportCsvPathWithQuery() {
      return `${this.exportCsvPath}${window.location.search}`;
    },
    getStatus(issue) {
      if (issue.closedAt && issue.movedToId) {
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
        const initBulkUpdateSidebar = await import('~/issuable_init_bulk_update_sidebar');
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
        this.page = 1;
      }
      this.state = state;
      this.fetchIssues();
    },
    handleFilter(filter) {
      this.filterTokens = filter;
      this.fetchIssues();
    },
    handlePageChange(page) {
      this.page = page;
      this.fetchIssues();
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
    handleSort(value) {
      this.sortKey = value;
      this.fetchIssues();
    },
    toggleBulkEditSidebar(showBulkEditSidebar) {
      this.showBulkEditSidebar = showBulkEditSidebar;
    },
  },
};
</script>

<template>
  <div v-if="hasIssues">
    <issuable-list
      :namespace="projectPath"
      recent-searches-storage-key="issues"
      :search-input-placeholder="$options.i18n.searchPlaceholder"
      :search-tokens="searchTokens"
      :initial-filter-value="filterTokens"
      :sort-options="sortOptions"
      :initial-sort-by="sortKey"
      :issuables="issues"
      :tabs="$options.IssuableListTabs"
      :current-tab="state"
      :tab-counts="tabCounts"
      :issuables-loading="isLoading"
      :is-manual-ordering="isManualOrdering"
      :show-bulk-edit-sidebar="showBulkEditSidebar"
      :show-pagination-controls="showPaginationControls"
      :total-items="totalIssues"
      :current-page="page"
      :previous-page="page - 1"
      :next-page="page + 1"
      :url-params="urlParams"
      @click-tab="handleClickTab"
      @filter="handleFilter"
      @page-change="handlePageChange"
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
          class="gl-mr-3"
          :export-csv-path="exportCsvPathWithQuery"
          :issuable-count="totalIssues"
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
          data-testid="issuable-mr"
        >
          <gl-icon name="merge-request" />
          {{ issuable.mergeRequestsCount }}
        </li>
        <li
          v-if="issuable.upvotes"
          v-gl-tooltip
          class="gl-display-none gl-sm-display-block"
          :title="$options.i18n.upvotes"
          data-testid="issuable-upvotes"
        >
          <gl-icon name="thumb-up" />
          {{ issuable.upvotes }}
        </li>
        <li
          v-if="issuable.downvotes"
          v-gl-tooltip
          class="gl-display-none gl-sm-display-block"
          :title="$options.i18n.downvotes"
          data-testid="issuable-downvotes"
        >
          <gl-icon name="thumb-down" />
          {{ issuable.downvotes }}
        </li>
        <blocking-issues-count
          class="gl-display-none gl-sm-display-block"
          :blocking-issues-count="issuable.blockingIssuesCount"
          :is-list-item="true"
        />
      </template>

      <template #empty-state>
        <gl-empty-state
          v-if="searchQuery"
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
          :issuable-count="totalIssues"
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
