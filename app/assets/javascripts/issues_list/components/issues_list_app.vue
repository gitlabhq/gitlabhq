<script>
import { GlButton, GlEmptyState, GlIcon, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { toNumber } from 'lodash';
import createFlash from '~/flash';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/issuable_list/constants';
import {
  CREATED_DESC,
  PAGE_SIZE,
  RELATIVE_POSITION_ASC,
  sortOptions,
  sortParams,
} from '~/issues_list/constants';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase, getParameterByName } from '~/lib/utils/common_utils';
import { __, s__ } from '~/locale';
import eventHub from '../eventhub';
import IssueCardTimeInfo from './issue_card_time_info.vue';

export default {
  CREATED_DESC,
  IssuableListTabs,
  PAGE_SIZE,
  sortOptions,
  sortParams,
  i18n: {
    calendarLabel: __('Subscribe to calendar'),
    jiraIntegrationMessage: s__(
      'JiraService|%{jiraDocsLinkStart}Enable the Jira integration%{jiraDocsLinkEnd} to view your Jira issues in GitLab.',
    ),
    jiraIntegrationSecondaryMessage: s__('JiraService|This feature requires a Premium plan.'),
    jiraIntegrationTitle: s__('JiraService|Using Jira for issue tracking?'),
    newIssueLabel: __('New issue'),
    noClosedIssuesTitle: __('There are no closed issues'),
    noOpenIssuesDescription: __('To keep this project going, create a new issue'),
    noOpenIssuesTitle: __('There are no open issues'),
    noIssuesSignedInDescription: __(
      'Issues can be bugs, tasks or ideas to be discussed. Also, issues are searchable and filterable.',
    ),
    noIssuesSignedInTitle: __(
      'The Issue Tracker is the place to add things that need to be improved or solved in a project',
    ),
    noIssuesSignedOutButtonText: __('Register / Sign In'),
    noIssuesSignedOutDescription: __(
      'The Issue Tracker is the place to add things that need to be improved or solved in a project. You can register or sign in to create issues for this project.',
    ),
    noIssuesSignedOutTitle: __('There are no issues to show'),
    noSearchResultsDescription: __('To widen your search, change or remove filters above'),
    noSearchResultsTitle: __('Sorry, your filter produced no results'),
    reorderError: __('An error occurred while reordering issues.'),
    rssLabel: __('Subscribe to RSS feed'),
  },
  components: {
    CsvImportExportButtons,
    GlButton,
    GlEmptyState,
    GlIcon,
    GlLink,
    GlSprintf,
    IssuableList,
    IssueCardTimeInfo,
    BlockingIssuesCount: () => import('ee_component/issues/components/blocking_issues_count.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
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
    fullPath: {
      default: '',
    },
    hasIssues: {
      default: false,
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
    const orderBy = getParameterByName('order_by');
    const sort = getParameterByName('sort');
    const sortKey = Object.keys(sortParams).find(
      (key) => sortParams[key].order_by === orderBy && sortParams[key].sort === sort,
    );

    const search = getParameterByName('search') || '';
    const tokens = search.split(' ').map((searchWord) => ({
      type: 'filtered-search-term',
      value: {
        data: searchWord,
      },
    }));

    return {
      exportCsvPathWithQuery: this.getExportCsvPathWithQuery(),
      filters: sortParams[sortKey] || {},
      filterTokens: tokens,
      isLoading: false,
      issues: [],
      page: toNumber(getParameterByName('page')) || 1,
      showBulkEditSidebar: false,
      sortKey: sortKey || CREATED_DESC,
      state: getParameterByName('state') || IssuableStates.Opened,
      totalIssues: 0,
    };
  },
  computed: {
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION_ASC;
    },
    isOpenTab() {
      return this.state === IssuableStates.Opened;
    },
    searchQuery() {
      return (
        this.filterTokens
          .map((searchTerm) => searchTerm.value.data)
          .filter((searchWord) => Boolean(searchWord))
          .join(' ') || undefined
      );
    },
    showPaginationControls() {
      return this.issues.length > 0;
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
        page: this.page,
        search: this.searchQuery,
        state: this.state,
        ...this.filters,
      };
    },
  },
  mounted() {
    eventHub.$on('issuables:toggleBulkEdit', (showBulkEditSidebar) => {
      this.showBulkEditSidebar = showBulkEditSidebar;
    });
    this.fetchIssues();
  },
  beforeDestroy() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    eventHub.$off('issuables:toggleBulkEdit');
  },
  methods: {
    fetchIssues() {
      if (!this.hasIssues) {
        return undefined;
      }

      this.isLoading = true;

      return axios
        .get(this.endpoint, {
          params: {
            page: this.page,
            per_page: this.$options.PAGE_SIZE,
            search: this.searchQuery,
            state: this.state,
            with_labels_details: true,
            ...this.filters,
          },
        })
        .then(({ data, headers }) => {
          this.page = Number(headers['x-page']);
          this.totalIssues = Number(headers['x-total']);
          this.issues = data.map((issue) => convertObjectPropsToCamelCase(issue, { deep: true }));
          this.exportCsvPathWithQuery = this.getExportCsvPathWithQuery();
        })
        .catch(() => {
          createFlash({ message: __('An error occurred while loading issues') });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    getExportCsvPathWithQuery() {
      return `${this.exportCsvPath}${window.location.search}`;
    },
    handleUpdateLegacyBulkEdit() {
      // If "select all" checkbox was checked, wait for all checkboxes
      // to be checked before updating IssuableBulkUpdateSidebar class
      this.$nextTick(() => {
        eventHub.$emit('issuables:updateBulkEdit');
      });
    },
    handleBulkUpdateClick() {
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
      this.filters = sortParams[value];
      this.fetchIssues();
    },
  },
};
</script>

<template>
  <issuable-list
    v-if="hasIssues"
    :namespace="fullPath"
    recent-searches-storage-key="issues"
    :search-input-placeholder="__('Search or filter results…')"
    :search-tokens="[]"
    :initial-filter-value="filterTokens"
    :sort-options="$options.sortOptions"
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
        class="gl-mr-3"
        :export-csv-path="exportCsvPathWithQuery"
        :issuable-count="totalIssues"
      />
      <gl-button
        v-if="canBulkUpdate"
        :disabled="showBulkEditSidebar"
        @click="handleBulkUpdateClick"
      >
        {{ __('Edit issues') }}
      </gl-button>
      <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
        {{ $options.i18n.newIssueLabel }}
      </gl-button>
    </template>

    <template #timeframe="{ issuable = {} }">
      <issue-card-time-info :issue="issuable" />
    </template>

    <template #statistics="{ issuable = {} }">
      <li
        v-if="issuable.mergeRequestsCount"
        v-gl-tooltip
        class="gl-display-none gl-sm-display-block"
        :title="__('Related merge requests')"
        data-testid="issuable-mr"
      >
        <gl-icon name="merge-request" />
        {{ issuable.mergeRequestsCount }}
      </li>
      <li
        v-if="issuable.upvotes"
        v-gl-tooltip
        class="gl-display-none gl-sm-display-block"
        :title="__('Upvotes')"
        data-testid="issuable-upvotes"
      >
        <gl-icon name="thumb-up" />
        {{ issuable.upvotes }}
      </li>
      <li
        v-if="issuable.downvotes"
        v-gl-tooltip
        class="gl-display-none gl-sm-display-block"
        :title="__('Downvotes')"
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
