<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import { STATUS_OPEN } from '~/issues/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { deriveSortKey } from '~/issues/list/utils';
import { __, s__ } from '~/locale';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import { STATE_CLOSED } from '../../constants';
import { sortOptions, urlSortParams } from '../constants';
import getWorkItemsQuery from '../queries/get_work_items.query.graphql';

export default {
  issuableListTabs,
  sortOptions,
  components: {
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
  },
  inject: ['fullPath', 'initialSort', 'isSignedIn'],
  data() {
    return {
      error: undefined,
      searchTokens: [],
      sortKey: deriveSortKey({ sort: this.initialSort, sortMap: urlSortParams }),
      state: STATUS_OPEN,
      workItems: [],
    };
  },
  apollo: {
    workItems: {
      query: getWorkItemsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          sort: this.sortKey,
        };
      },
      update(data) {
        return data.group.workItems.nodes ?? [];
      },
      error(error) {
        this.error = s__(
          'WorkItem|Something went wrong when fetching work items. Please try again.',
        );
        Sentry.captureException(error);
      },
    },
  },
  methods: {
    getStatus(issue) {
      return issue.state === STATE_CLOSED ? __('Closed') : undefined;
    },
    handleSort(sortKey) {
      if (this.sortKey === sortKey) {
        return;
      }

      this.sortKey = sortKey;

      if (this.isSignedIn) {
        this.saveSortPreference(sortKey);
      }
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
  },
};
</script>

<template>
  <issuable-list
    :current-tab="state"
    :error="error"
    :initial-sort-by="sortKey"
    :issuables="workItems"
    :issuables-loading="$apollo.queries.workItems.loading"
    namespace="work-items"
    recent-searches-storage-key="issues"
    :search-tokens="searchTokens"
    show-work-item-type-icon
    :sort-options="$options.sortOptions"
    :tabs="$options.issuableListTabs"
    @dismiss-alert="error = undefined"
    @sort="handleSort"
  >
    <template #nav-actions>
      <slot name="nav-actions"></slot>
    </template>

    <template #timeframe="{ issuable = {} }">
      <issue-card-time-info :issue="issuable" />
    </template>

    <template #status="{ issuable }">
      {{ getStatus(issuable) }}
    </template>

    <template #statistics="{ issuable = {} }">
      <issue-card-statistics :issue="issuable" />
    </template>

    <template #list-body>
      <slot name="list-body"></slot>
    </template>
  </issuable-list>
</template>
