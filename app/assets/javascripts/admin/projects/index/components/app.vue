<script>
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
  FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL,
  PAGINATION_TYPE_KEYSET,
} from '~/groups_projects/constants';
import {
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/projects/filtered_search_and_sort/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import projectCountsQuery from '~/admin/projects/index/graphql/queries/project_counts.query.graphql';
import { ADMIN_PROJECTS_TABS, FIRST_TAB_ROUTE_NAMES } from '~/admin/projects/index/constants';

export default {
  ADMIN_PROJECTS_TABS,
  FIRST_TAB_ROUTE_NAMES,
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  filteredSearchSupportedTokens: [
    FILTERED_SEARCH_TOKEN_LANGUAGE,
    FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
    FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL,
  ],
  timestampTypeMap: {
    [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
  },
  tabCountsQuery: projectCountsQuery,
  PAGINATION_TYPE_KEYSET,
  name: 'AdminProjectsApp',
  components: {
    TabsWithList,
  },
  props: {
    programmingLanguages: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <tabs-with-list
    :tabs="$options.ADMIN_PROJECTS_TABS"
    :filtered-search-supported-tokens="$options.filteredSearchSupportedTokens"
    :filtered-search-term-key="$options.FILTERED_SEARCH_TERM_KEY"
    :filtered-search-namespace="$options.FILTERED_SEARCH_NAMESPACE"
    :filtered-search-recent-searches-storage-key="$options.RECENT_SEARCHES_STORAGE_KEY_PROJECTS"
    :sort-options="$options.SORT_OPTIONS"
    :default-sort-option="$options.SORT_OPTION_UPDATED"
    :timestamp-type-map="$options.timestampTypeMap"
    :first-tab-route-names="$options.FIRST_TAB_ROUTE_NAMES"
    initial-sort=""
    :programming-languages="programmingLanguages"
    :tab-counts-query="$options.tabCountsQuery"
    :tab-counts-query-error-message="__('An error occurred loading the project counts.')"
    :pagination-type="$options.PAGINATION_TYPE_KEYSET"
  />
</template>
