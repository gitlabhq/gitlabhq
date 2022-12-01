<script>
import { GlButton, GlEmptyState, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import getIssuesQuery from 'ee_else_ce/issues/dashboard/queries/get_issues.query.graphql';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import { IssuableStatus } from '~/issues/constants';
import { PAGE_SIZE } from '~/issues/list/constants';
import { getInitialPageParams } from '~/issues/list/utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { __ } from '~/locale';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { IssuableListTabs, IssuableStates } from '~/vue_shared/issuable/list/constants';

export default {
  i18n: {
    calendarButtonText: __('Subscribe to calendar'),
    closed: __('CLOSED'),
    closedMoved: __('CLOSED (MOVED)'),
    downvotes: __('Downvotes'),
    emptyStateTitle: __('Please select at least one filter to see results'),
    errorFetchingIssues: __('An error occurred while loading issues'),
    relatedMergeRequests: __('Related merge requests'),
    rssButtonText: __('Subscribe to RSS feed'),
    searchInputPlaceholder: __('Search or filter results...'),
    upvotes: __('Upvotes'),
  },
  IssuableListTabs,
  components: {
    GlButton,
    GlEmptyState,
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'calendarPath',
    'emptyStateSvgPath',
    'hasScopedLabelsFeature',
    'isPublicVisibilityRestricted',
    'isSignedIn',
    'rssPath',
  ],
  data() {
    return {
      issues: [],
      issuesError: null,
      pageInfo: {},
      pageParams: getInitialPageParams(),
      searchTokens: [],
      sortOptions: [],
      state: IssuableStates.Opened,
    };
  },
  apollo: {
    issues: {
      query: getIssuesQuery,
      variables() {
        return {
          hideUsers: this.isPublicVisibilityRestricted && !this.isSignedIn,
          isSignedIn: this.isSignedIn,
          state: this.state,
          ...this.pageParams,
        };
      },
      update(data) {
        return data.issues.nodes ?? [];
      },
      result({ data }) {
        this.pageInfo = data?.issues.pageInfo ?? {};
      },
      error(error) {
        this.issuesError = this.$options.i18n.errorFetchingIssues;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    showPaginationControls() {
      return this.issues.length > 0 && (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage);
    },
  },
  methods: {
    getStatus(issue) {
      if (issue.state === IssuableStatus.Closed && issue.moved) {
        return this.$options.i18n.closedMoved;
      }
      if (issue.state === IssuableStatus.Closed) {
        return this.$options.i18n.closed;
      }
      return undefined;
    },
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }
      this.pageParams = getInitialPageParams();
      this.state = state;
    },
    handleDismissAlert() {
      this.issuesError = null;
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
  },
};
</script>

<template>
  <issuable-list
    :current-tab="state"
    :error="issuesError"
    :has-next-page="pageInfo.hasNextPage"
    :has-previous-page="pageInfo.hasPreviousPage"
    :has-scoped-labels-feature="hasScopedLabelsFeature"
    :issuables="issues"
    :issuables-loading="$apollo.queries.issues.loading"
    namespace="dashboard"
    recent-searches-storage-key="issues"
    :search-input-placeholder="$options.i18n.searchInputPlaceholder"
    :search-tokens="searchTokens"
    :show-pagination-controls="showPaginationControls"
    :sort-options="sortOptions"
    :tabs="$options.IssuableListTabs"
    use-keyset-pagination
    @click-tab="handleClickTab"
    @dismiss-alert="handleDismissAlert"
    @next-page="handleNextPage"
    @previous-page="handlePreviousPage"
  >
    <template #nav-actions>
      <gl-button :href="rssPath" icon="rss">
        {{ $options.i18n.rssButtonText }}
      </gl-button>
      <gl-button :href="calendarPath" icon="calendar">
        {{ $options.i18n.calendarButtonText }}
      </gl-button>
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
      <gl-empty-state :svg-path="emptyStateSvgPath" :title="$options.i18n.emptyStateTitle" />
    </template>
  </issuable-list>
</template>
