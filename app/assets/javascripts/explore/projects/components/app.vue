<script>
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '~/groups_projects/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import {
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
} from '~/projects/filtered_search_and_sort/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import {
  EXPLORE_PROJECTS_TABS,
  FILTERED_SEARCH_NAMESPACE,
  FILTERED_SEARCH_TERM_KEY,
  TRENDING_TAB,
} from '~/explore/projects/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  EXPLORE_PROJECTS_TABS,
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
      [FILTERED_SEARCH_TERM_KEY]: 'search_on_explore_projects',
      [FILTERED_SEARCH_TOKEN_LANGUAGE]: 'filter_by_language_on_explore_projects',
      [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: 'filter_by_role_on_explore_projects',
    },
    pagination: 'click_pagination_on_explore_projects',
    tabs: 'click_tab_on_explore_projects',
    sort: 'click_sort_on_explore_projects',
    clickStat: 'click_stat_on_explore_projects',
    hoverStat: 'hover_stat_on_explore_projects',
    hoverVisibility: 'hover_visibility_icon_on_explore_projects',
    initialLoad: 'initial_load_on_explore_projects',
    clickItemAfterFilter: 'click_project_after_filter_on_explore_projects',
    clickTopic: 'click_topic_on_explore_projects',
  },
  name: 'ExploreProjectsApp',
  components: {
    TabsWithList,
  },
  mixins: [glFeatureFlagMixin()],
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
  computed: {
    tabs() {
      if (this.glFeatures.retireTrendingProjects) {
        return this.$options.EXPLORE_PROJECTS_TABS.filter(
          (tab) => tab.value !== TRENDING_TAB.value,
        );
      }

      return this.$options.EXPLORE_PROJECTS_TABS;
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
    :timestamp-type-map="$options.timestampTypeMap"
    :initial-sort="initialSort"
    :programming-languages="programmingLanguages"
    :event-tracking="$options.eventTracking"
    user-preferences-sort-key="projectsSort"
  />
</template>
