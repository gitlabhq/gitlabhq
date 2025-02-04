<script>
import { GlTabs, GlTab, GlBadge, GlFilteredSearchToken } from '@gitlab/ui';
import { isEqual, pick } from 'lodash';
import { __ } from '~/locale';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from '~/graphql_shared/constants';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { createAlert } from '~/alert';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import { calculateGraphQLPaginationQueryParams } from '~/graphql_shared/utils';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { ACCESS_LEVEL_OWNER_INTEGER } from '~/access_level/constants';
import {
  SORT_OPTIONS,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_OPTION_UPDATED,
  SORT_OPTION_CREATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '~/projects/filtered_search_and_sort/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  CONTRIBUTED_TAB,
  CUSTOM_DASHBOARD_ROUTE_NAMES,
  PROJECT_DASHBOARD_TABS,
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '../constants';
import projectCountsQuery from '../graphql/queries/project_counts.query.graphql';
import userPreferencesUpdateMutation from '../graphql/mutations/user_preferences_update.mutation.graphql';
import TabView from './tab_view.vue';

export default {
  name: 'YourWorkProjectsApp',
  PROJECT_DASHBOARD_TABS,
  i18n: {
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

          return {
            contributed: contributed.count,
            starred: starred.count,
            personal: personal.count,
            member: member.count,
            inactive: inactive.count,
          };
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
          type: FILTERED_SEARCH_TOKEN_LANGUAGE,
          icon: 'code',
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
          type: FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
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
    startCursor() {
      return this.$route.query[QUERY_PARAM_START_CURSOR];
    },
    endCursor() {
      return this.$route.query[QUERY_PARAM_END_CURSOR];
    },
    routeQueryWithoutPagination() {
      const {
        [QUERY_PARAM_START_CURSOR]: startCursor,
        [QUERY_PARAM_END_CURSOR]: endCursor,
        ...routeQuery
      } = this.$route.query;

      return routeQuery;
    },
    filters() {
      const filters = pick(this.routeQueryWithoutPagination, [
        FILTERED_SEARCH_TOKEN_LANGUAGE,
        FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
        FILTERED_SEARCH_TERM_KEY,
      ]);

      // Normalize the property to Number since Vue Router 4 will
      // return this and all other query variables as a string
      filters[FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL] = Number(
        filters[FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL],
      );

      return filters;
    },
    timestampType() {
      const SORT_MAP = {
        [SORT_OPTION_CREATED.value]: TIMESTAMP_TYPE_CREATED_AT,
        [SORT_OPTION_UPDATED.value]: TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
      };

      return SORT_MAP[this.activeSortOption.value] || TIMESTAMP_TYPE_CREATED_AT;
    },
  },
  methods: {
    numberToMetricPrefix,
    createSortQuery({ sortBy, isAscending }) {
      return `${sortBy}_${isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC}`;
    },
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
      const sort = this.createSortQuery({ sortBy: this.activeSortOption.value, isAscending });

      this.updateSort(sort);
    },
    onSortByChange(sortBy) {
      const sort = this.createSortQuery({ sortBy, isAscending: this.isAscending });

      this.updateSort(sort);
    },
    updateSort(sort) {
      this.pushQuery({ ...this.routeQueryWithoutPagination, sort });
      this.userPreferencesUpdateMutate(sort);
    },
    onFilter(filters) {
      const { sort } = this.$route.query;

      this.pushQuery({ sort, ...filters });
    },
    onPageChange(pagination) {
      this.pushQuery(
        calculateGraphQLPaginationQueryParams({ ...pagination, routeQuery: this.$route.query }),
      );
    },
    async userPreferencesUpdateMutate(sort) {
      try {
        await this.$apollo.mutate({
          mutation: userPreferencesUpdateMutation,
          variables: {
            input: {
              projectsSort: sort.toUpperCase(),
            },
          },
        });
      } catch (error) {
        // Silently fail but capture exception in Sentry
        Sentry.captureException(error);
      }
    },
  },
};
</script>

<template>
  <gl-tabs :value="activeTabIndex" @input="onTabUpdate">
    <gl-tab v-for="tab in $options.PROJECT_DASHBOARD_TABS" :key="tab.text" lazy>
      <template #title>
        <div class="gl-flex gl-items-center gl-gap-2" data-testid="projects-dashboard-tab-title">
          <span>{{ tab.text }}</span>
          <gl-badge
            v-if="shouldShowCountBadge(tab)"
            size="sm"
            class="gl-tab-counter-badge"
            data-testid="tab-counter-badge"
            >{{ numberToMetricPrefix(tabCount(tab)) }}</gl-badge
          >
        </div>
      </template>

      <tab-view
        v-if="tab.query"
        :tab="tab"
        :start-cursor="startCursor"
        :end-cursor="endCursor"
        :sort="sort"
        :filters="filters"
        :timestamp-type="timestampType"
        @page-change="onPageChange"
      />
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
</template>
