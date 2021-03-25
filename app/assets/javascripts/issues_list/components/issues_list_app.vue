<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { toNumber } from 'lodash';
import createFlash from '~/flash';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import { IssuableStatus } from '~/issue_show/constants';
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
  PAGE_SIZE,
  sortOptions,
  sortParams,
  i18n: {
    reorderError: __('An error occurred while reordering issues.'),
  },
  components: {
    GlIcon,
    IssuableList,
    IssueCardTimeInfo,
    BlockingIssuesCount: () => import('ee_component/issues/components/blocking_issues_count.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    endpoint: {
      default: '',
    },
    fullPath: {
      default: '',
    },
    issuesPath: {
      default: '',
    },
  },
  data() {
    const orderBy = getParameterByName('order_by');
    const sort = getParameterByName('sort');
    const sortKey = Object.keys(sortParams).find(
      (key) => sortParams[key].order_by === orderBy && sortParams[key].sort === sort,
    );

    return {
      currentPage: toNumber(getParameterByName('page')) || 1,
      filters: sortParams[sortKey] || {},
      isLoading: false,
      issues: [],
      showBulkEditSidebar: false,
      sortKey: sortKey || CREATED_DESC,
      totalIssues: 0,
    };
  },
  computed: {
    urlParams() {
      return {
        page: this.currentPage,
        state: IssuableStatus.Open,
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
    fetchIssues(pageToFetch) {
      this.isLoading = true;

      return axios
        .get(this.endpoint, {
          params: {
            page: pageToFetch || this.currentPage,
            per_page: this.$options.PAGE_SIZE,
            state: IssuableStatus.Open,
            with_labels_details: true,
            ...this.filters,
          },
        })
        .then(({ data, headers }) => {
          this.currentPage = Number(headers['x-page']);
          this.totalIssues = Number(headers['x-total']);
          this.issues = data.map((issue) => convertObjectPropsToCamelCase(issue, { deep: true }));
        })
        .catch(() => {
          createFlash({ message: __('An error occurred while loading issues') });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    handleUpdateLegacyBulkEdit() {
      // If "select all" checkbox was checked, wait for all checkboxes
      // to be checked before updating IssuableBulkUpdateSidebar class
      this.$nextTick(() => {
        eventHub.$emit('issuables:updateBulkEdit');
      });
    },
    handlePageChange(page) {
      this.fetchIssues(page);
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
    :tabs="[]"
    current-tab=""
    :issuables-loading="isLoading"
    :is-manual-ordering="isManualOrdering"
    :show-bulk-edit-sidebar="showBulkEditSidebar"
    :show-pagination-controls="true"
    :total-items="totalIssues"
    :current-page="currentPage"
    :previous-page="currentPage - 1"
    :next-page="currentPage + 1"
    :url-params="urlParams"
    @page-change="handlePageChange"
    @reorder="handleReorder"
    @sort="handleSort"
    @update-legacy-bulk-edit="handleUpdateLegacyBulkEdit"
  >
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
