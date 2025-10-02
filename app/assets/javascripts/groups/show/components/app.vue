<script>
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import {
  GROUPS_SHOW_TABS,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  SHARED_PROJECTS_TAB,
  SHARED_GROUPS_TAB,
} from '../constants';

export default {
  GROUPS_SHOW_TABS,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  RECENT_SEARCHES_STORAGE_KEY_GROUPS,
  timestampTypeMap: {
    [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_UPDATED_AT,
  },
  name: 'GroupsShowApp',
  components: { TabsWithList },
  props: {
    initialSort: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    tabs() {
      const tabsWithFullPathVariable = [SHARED_PROJECTS_TAB.value, SHARED_GROUPS_TAB.value];
      return GROUPS_SHOW_TABS.map((tab) => {
        if (tabsWithFullPathVariable.includes(tab.value)) {
          return {
            ...tab,
            variables: {
              fullPath: this.fullPath,
            },
          };
        }

        return tab;
      });
    },
  },
};
</script>

<template>
  <tabs-with-list
    :tabs="tabs"
    :filtered-search-term-key="$options.FILTERED_SEARCH_TERM_KEY"
    :filtered-search-namespace="$options.FILTERED_SEARCH_NAMESPACE"
    :filtered-search-recent-searches-storage-key="$options.RECENT_SEARCHES_STORAGE_KEY_GROUPS"
    :filtered-search-input-placeholder="__('Search (3 character minimum)')"
    :sort-options="$options.SORT_OPTIONS"
    :default-sort-option="$options.SORT_OPTION_UPDATED"
    :timestamp-type-map="$options.timestampTypeMap"
    :initial-sort="initialSort"
    :should-update-active-tab-count-from-tab-query="false"
    user-preferences-sort-key="projectsSort"
  />
</template>
