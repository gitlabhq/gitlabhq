<script>
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { PAGINATION_TYPE_OFFSET } from '~/groups_projects/constants';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import groupCountsQuery from '../graphql/queries/group_counts.query.graphql';
import {
  GROUP_DASHBOARD_TABS,
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '../constants';

export default {
  GROUP_DASHBOARD_TABS,
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  RECENT_SEARCHES_STORAGE_KEY_GROUPS,
  timestampTypeMap: {
    [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_UPDATED_AT,
  },
  PAGINATION_TYPE_OFFSET,
  tabCountsQuery: groupCountsQuery,
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
    :sort-options="$options.SORT_OPTIONS"
    :default-sort-option="$options.SORT_OPTION_UPDATED"
    :timestamp-type-map="$options.timestampTypeMap"
    :initial-sort="initialSort"
    :tab-counts-query="$options.tabCountsQuery"
    :tab-counts-query-error-message="__('An error occurred loading the group counts.')"
    :should-update-active-tab-count-from-tab-query="false"
    :pagination-type="$options.PAGINATION_TYPE_OFFSET"
  />
</template>
