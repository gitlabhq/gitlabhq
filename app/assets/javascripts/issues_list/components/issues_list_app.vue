<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
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
import { __ } from '~/locale';
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
    reorderError: __('An error occurred while reordering issues.'),
    rssLabel: __('Subscribe to RSS feed'),
  },
  components: {
    CsvImportExportButtons,
    GlButton,
    GlIcon,
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
    endpoint: {
      default: '',
    },
    exportCsvPath: {
      default: '',
    },
    fullPath: {
      default: '',
    },
    issuesPath: {
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
  },
  data() {
    const orderBy = getParameterByName('order_by');
    const sort = getParameterByName('sort');
    const sortKey = Object.keys(sortParams).find(
      (key) => sortParams[key].order_by === orderBy && sortParams[key].sort === sort,
    );

    return {
      exportCsvPathWithQuery: this.getExportCsvPathWithQuery(),
      filters: sortParams[sortKey] || {},
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
        state: this.state,
        ...this.filters,
      };
    },
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION_ASC;
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
      this.isLoading = true;

      return axios
        .get(this.endpoint, {
          params: {
            page: this.page,
            per_page: this.$options.PAGE_SIZE,
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
    :namespace="fullPath"
    recent-searches-storage-key="issues"
    :search-input-placeholder="__('Search or filter results…')"
    :search-tokens="[]"
    :sort-options="$options.sortOptions"
    :initial-sort-by="sortKey"
    :issuables="issues"
    :tabs="$options.IssuableListTabs"
    :current-tab="state"
    :tab-counts="tabCounts"
    :issuables-loading="isLoading"
    :is-manual-ordering="isManualOrdering"
    :show-bulk-edit-sidebar="showBulkEditSidebar"
    :show-pagination-controls="true"
    :total-items="totalIssues"
    :current-page="page"
    :previous-page="page - 1"
    :next-page="page + 1"
    :url-params="urlParams"
    @click-tab="handleClickTab"
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
        {{ __('New issue') }}
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
  </issuable-list>
</template>
