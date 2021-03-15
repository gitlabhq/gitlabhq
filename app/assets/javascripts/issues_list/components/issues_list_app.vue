<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { toNumber } from 'lodash';
import createFlash from '~/flash';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import { IssuableStatus } from '~/issue_show/constants';
import { PAGE_SIZE } from '~/issues_list/constants';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase, getParameterByName } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import IssueCardTimeInfo from './issue_card_time_info.vue';

export default {
  PAGE_SIZE,
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
  },
  data() {
    return {
      currentPage: toNumber(getParameterByName('page')) || 1,
      isLoading: false,
      issues: [],
      totalIssues: 0,
    };
  },
  computed: {
    urlParams() {
      return {
        page: this.currentPage,
        state: IssuableStatus.Open,
      };
    },
  },
  mounted() {
    this.fetchIssues();
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
    handlePageChange(page) {
      this.fetchIssues(page);
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
    :sort-options="[]"
    :issuables="issues"
    :tabs="[]"
    current-tab=""
    :issuables-loading="isLoading"
    :show-pagination-controls="true"
    :total-items="totalIssues"
    :current-page="currentPage"
    :previous-page="currentPage - 1"
    :next-page="currentPage + 1"
    :url-params="urlParams"
    @page-change="handlePageChange"
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
