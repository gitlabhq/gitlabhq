<script>
import { GlTabs, GlTab, GlBadge, GlFilteredSearchToken } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { __ } from '~/locale';
import { TIMESTAMP_TYPE_UPDATED_AT } from '~/vue_shared/components/resource_lists/constants';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { createAlert } from '~/alert';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { ACCESS_LEVEL_OWNER_INTEGER } from '~/access_level/constants';
import {
  SORT_OPTIONS,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_OPTION_UPDATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/projects/filtered_search_and_sort/constants';
import {
  CONTRIBUTED_TAB,
  CUSTOM_DASHBOARD_ROUTE_NAMES,
  PROJECT_DASHBOARD_TABS,
} from '../constants';
import projectCountsQuery from '../graphql/queries/project_counts.query.graphql';
import TabView from './tab_view.vue';

export default {
  name: 'YourWorkProjectsApp',
  TIMESTAMP_TYPE_UPDATED_AT,
  PROJECT_DASHBOARD_TABS,
  i18n: {
    heading: __('Projects'),
    projectCountError: __('An error occurred loading the project counts.'),
  },
  filteredSearchAndSort: {
    sortOptions: SORT_OPTIONS,
    namespace: FILTERED_SEARCH_NAMESPACE,
    recentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
    searchTermKey: FILTERED_SEARCH_TERM_KEY,
  },
  components: {
    GlTabs,
    GlTab,
    GlBadge,
    TabView,
    FilteredSearchAndSort,
  },
  inject: ['initialSort', 'programmingLanguages'],
  data() {
    return {
      activeTabIndex: this.initActiveTabIndex(),
      counts: PROJECT_DASHBOARD_TABS.reduce((accumulator, tab) => {
        return {
          ...accumulator,
          [tab.value]: undefined,
        };
      }, {}),
    };
  },
  apollo: {
    counts() {
      return {
        query: projectCountsQuery,
        update(response) {
          const {
            currentUser: { contributed, starred },
            personal,
            member,
            inactive,
          } = response;

          return Object.entries({ contributed, starred, personal, member, inactive }).reduce(
            (accumulator, [tab, item]) => {
              return {
                ...accumulator,
                [tab]: item.count,
              };
            },
            {},
          );
        },
        error(error) {
          createAlert({ message: this.$options.i18n.projectCountError, error, captureError: true });
        },
      };
    },
  },
  computed: {
    filteredSearchTokens() {
      return [
        {
          type: 'language',
          icon: 'lock',
          title: __('Language'),
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: this.programmingLanguages.map(({ id, name }) => ({
            // Cast to string so it matches value from query string
            value: id.toString(),
            title: name,
          })),
        },
        {
          type: 'min_access_level',
          icon: 'user',
          title: __('Role'),
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            {
              // Cast to string so it matches value from query string
              value: ACCESS_LEVEL_OWNER_INTEGER.toString(),
              title: __('Owner'),
            },
          ],
        },
      ];
    },
    sortQuery() {
      return this.$route.query.sort;
    },
    sort() {
      if (this.sortQuery) {
        return this.sortQuery;
      }

      return this.initialSort || `${SORT_OPTION_UPDATED.value}_${SORT_DIRECTION_ASC}`;
    },
    activeSortOption() {
      return SORT_OPTIONS.find((sortItem) => this.sort.includes(sortItem.value));
    },
    isAscending() {
      return this.sort.endsWith(SORT_DIRECTION_ASC);
    },
  },
  methods: {
    numberToMetricPrefix,
    pushQuery(query) {
      if (isEqual(this.$route.query, query)) {
        return;
      }

      this.$router.push({ query });
    },
    initActiveTabIndex() {
      return CUSTOM_DASHBOARD_ROUTE_NAMES.includes(this.$route.name)
        ? 0
        : PROJECT_DASHBOARD_TABS.findIndex((tab) => tab.value === this.$route.name);
    },
    onTabUpdate(index) {
      // This return will prevent us overwriting the root `/` and `/dashboard/projects` paths
      // when we don't need to.
      if (index === this.activeTabIndex) return;

      this.activeTabIndex = index;

      const tab = PROJECT_DASHBOARD_TABS[index] || CONTRIBUTED_TAB;
      this.$router.push({ name: tab.value });
    },
    tabCount(tab) {
      return this.counts[tab.value];
    },
    shouldShowCountBadge(tab) {
      return this.tabCount(tab) !== undefined;
    },
    onSortDirectionChange(isAscending) {
      const sort = `${this.activeSortOption.value}_${
        isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC
      }`;

      this.pushQuery({ ...this.$route.query, sort });
    },
    onSortByChange(sortBy) {
      const sort = `${sortBy}_${this.isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC}`;

      this.pushQuery({ ...this.$route.query, sort });
    },
    onFilter(filters) {
      const { sort } = this.$route.query;

      this.pushQuery({ sort, ...filters });
    },
  },
};
</script>

<template>
  <div>
    <h1 class="page-title gl-mt-5 gl-text-size-h-display">{{ $options.i18n.heading }}</h1>

    <gl-tabs :value="activeTabIndex" @input="onTabUpdate">
      <gl-tab v-for="tab in $options.PROJECT_DASHBOARD_TABS" :key="tab.text" lazy>
        <template #title>
          <div class="gl-flex gl-items-center gl-gap-2" data-testid="projects-dashboard-tab-title">
            <span>{{ tab.text }}</span>
            <gl-badge v-if="shouldShowCountBadge(tab)" size="sm" class="gl-tab-counter-badge">{{
              numberToMetricPrefix(tabCount(tab))
            }}</gl-badge>
          </div>
        </template>

        <tab-view v-if="tab.query" :tab="tab" />
        <template v-else>{{ tab.text }}</template>
      </gl-tab>

      <template #tabs-end>
        <li class="gl-w-full">
          <filtered-search-and-sort
            class="gl-border-b-0"
            :filtered-search-namespace="$options.filteredSearchAndSort.namespace"
            :filtered-search-tokens="filteredSearchTokens"
            :filtered-search-term-key="$options.filteredSearchAndSort.searchTermKey"
            :filtered-search-recent-searches-storage-key="
              $options.filteredSearchAndSort.recentSearchesStorageKey
            "
            :filtered-search-query="$route.query"
            :is-ascending="isAscending"
            :sort-options="$options.filteredSearchAndSort.sortOptions"
            :active-sort-option="activeSortOption"
            @filter="onFilter"
            @sort-direction-change="onSortDirectionChange"
            @sort-by-change="onSortByChange"
          />
        </li>
      </template>
    </gl-tabs>
  </div>
</template>
