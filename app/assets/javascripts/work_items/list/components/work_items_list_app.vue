<script>
import * as Sentry from '@sentry/browser';
import { STATUS_OPEN } from '~/issues/constants';
import { __, s__ } from '~/locale';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import { STATE_CLOSED } from '../../constants';
import getWorkItemsQuery from '../queries/get_work_items.query.graphql';

export default {
  i18n: {
    searchPlaceholder: __('Search or filter results...'),
  },
  issuableListTabs,
  components: {
    IssuableList,
  },
  inject: ['fullPath'],
  data() {
    return {
      error: undefined,
      searchTokens: [],
      sortOptions: [],
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
  },
};
</script>

<template>
  <issuable-list
    :current-tab="state"
    :error="error"
    :issuables="workItems"
    namespace="work-items"
    recent-searches-storage-key="issues"
    :search-input-placeholder="$options.i18n.searchPlaceholder"
    :search-tokens="searchTokens"
    show-work-item-type-icon
    :sort-options="sortOptions"
    :tabs="$options.issuableListTabs"
    @dismiss-alert="error = undefined"
  >
    <template #status="{ issuable }">
      {{ getStatus(issuable) }}
    </template>
  </issuable-list>
</template>
