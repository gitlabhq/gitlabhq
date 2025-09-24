<script>
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import groupCountsQuery from '../graphql/queries/group_counts.query.graphql';
import {
  GROUP_DASHBOARD_TABS,
  FIRST_TAB_ROUTE_NAMES,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '../constants';

export default {
  GROUP_DASHBOARD_TABS,
  FIRST_TAB_ROUTE_NAMES,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  RECENT_SEARCHES_STORAGE_KEY_GROUPS,
  timestampTypeMap: {
    [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_UPDATED_AT,
  },
  tabCountsQuery: groupCountsQuery,
  eventTracking: {
    filteredSearch: {
      [FILTERED_SEARCH_TERM_KEY]: 'search_on_your_work_groups',
    },
    pagination: 'click_pagination_on_your_work_groups',
    tabs: 'click_tab_on_your_work_groups',
    sort: 'click_sort_on_your_work_groups',
  },
  name: 'YourWorkGroupsApp',
  components: { TabsWithList },
  props: {
    initialSort: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <tabs-with-list
    :tabs="$options.GROUP_DASHBOARD_TABS"
    :filtered-search-term-key="$options.FILTERED_SEARCH_TERM_KEY"
    :filtered-search-namespace="$options.FILTERED_SEARCH_NAMESPACE"
    :filtered-search-recent-searches-storage-key="$options.RECENT_SEARCHES_STORAGE_KEY_GROUPS"
    :filtered-search-input-placeholder="__('Search')"
    :timestamp-type-map="$options.timestampTypeMap"
    :first-tab-route-names="$options.FIRST_TAB_ROUTE_NAMES"
    :initial-sort="initialSort"
    :tab-counts-query="$options.tabCountsQuery"
    :tab-counts-query-error-message="__('An error occurred loading the group counts.')"
    :should-update-active-tab-count-from-tab-query="false"
    :event-tracking="$options.eventTracking"
  />
</template>
