<script>
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
  FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL,
  FILTERED_SEARCH_TOKEN_NAMESPACE,
  FILTERED_SEARCH_TOKEN_REPOSITORY_CHECK_FAILED,
} from '~/groups_projects/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import projectCountsQuery from '~/admin/projects/index/graphql/queries/project_counts.query.graphql';
import adminProjectsQuery from '~/admin/projects/index/graphql/queries/admin_projects.query.graphql';
import {
  ADMIN_PROJECTS_TABS,
  SORT_OPTIONS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FIRST_TAB_ROUTE_NAMES,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/admin/projects/index/constants';

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
    FILTERED_SEARCH_TOKEN_NAMESPACE,
    FILTERED_SEARCH_TOKEN_REPOSITORY_CHECK_FAILED,
  ],
  timestampTypeMap: {
    [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
  },
  tabCountsQuery: projectCountsQuery,
  name: 'AdminProjectsApp',
  components: {
    TabsWithList,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    programmingLanguages: {
      type: Array,
      required: true,
    },
  },
  computed: {
    tabs() {
      const tabs = this.$options.ADMIN_PROJECTS_TABS;

      if (this.glFeatures.customAbilityReadAdminProjects) {
        return tabs.map((tab) => ({ ...tab, query: adminProjectsQuery }));
      }

      return tabs;
    },
  },
};
</script>

<template>
  <tabs-with-list
    :tabs="tabs"
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
  />
</template>
