<script>
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import {
  FILTERED_SEARCH_NAMESPACE,
  FILTERED_SEARCH_TERM_KEY,
  EXPLORE_GROUPS_TABS,
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
} from '~/explore/groups/constants';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';

export default {
  EXPLORE_GROUPS_TABS,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  RECENT_SEARCHES_STORAGE_KEY_GROUPS,
  timestampTypeMap: {
    [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_UPDATED_AT,
  },
  name: 'ExploreGroupsApp',
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
    :tabs="$options.EXPLORE_GROUPS_TABS"
    :filtered-search-term-key="$options.FILTERED_SEARCH_TERM_KEY"
    :filtered-search-namespace="$options.FILTERED_SEARCH_NAMESPACE"
    :filtered-search-recent-searches-storage-key="$options.RECENT_SEARCHES_STORAGE_KEY_GROUPS"
    :filtered-search-input-placeholder="__('Search')"
    :timestamp-type-map="$options.timestampTypeMap"
    :initial-sort="initialSort"
    :should-update-active-tab-count-from-tab-query="false"
  />
</template>
