<script>
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '~/groups_projects/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import {
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/projects/filtered_search_and_sort/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { PROJECT_DASHBOARD_TABS, FIRST_TAB_ROUTE_NAMES } from '../constants';

export default {
  PROJECT_DASHBOARD_TABS,
  FIRST_TAB_ROUTE_NAMES,
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  filteredSearchSupportedTokens: [
    FILTERED_SEARCH_TOKEN_LANGUAGE,
    FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
  ],
  timestampTypeMap: {
    [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
  },
  eventTracking: {
    filteredSearch: {
      [FILTERED_SEARCH_TERM_KEY]: 'search_on_your_work_projects',
      [FILTERED_SEARCH_TOKEN_LANGUAGE]: 'filter_by_language_on_your_work_projects',
      [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: 'filter_by_role_on_your_work_projects',
    },
    pagination: 'click_pagination_on_your_work_projects',
    tabs: 'click_tab_on_your_work_projects',
    sort: 'click_sort_on_your_work_projects',
  },
  name: 'YourWorkProjectsApp',
  components: {
    TabsWithList,
  },
  props: {
    initialSort: {
      type: String,
      required: true,
    },
    programmingLanguages: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <tabs-with-list
    :tabs="$options.PROJECT_DASHBOARD_TABS"
    :filtered-search-supported-tokens="$options.filteredSearchSupportedTokens"
    :filtered-search-term-key="$options.FILTERED_SEARCH_TERM_KEY"
    :filtered-search-namespace="$options.FILTERED_SEARCH_NAMESPACE"
    :filtered-search-recent-searches-storage-key="$options.RECENT_SEARCHES_STORAGE_KEY_PROJECTS"
    :sort-options="$options.SORT_OPTIONS"
    :default-sort-option="$options.SORT_OPTION_UPDATED"
    :timestamp-type-map="$options.timestampTypeMap"
    :first-tab-route-names="$options.FIRST_TAB_ROUTE_NAMES"
    :initial-sort="initialSort"
    :programming-languages="programmingLanguages"
    :event-tracking="$options.eventTracking"
  />
</template>
