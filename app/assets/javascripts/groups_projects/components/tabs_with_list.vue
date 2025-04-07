<script>
import { GlTabs, GlTab, GlBadge, GlFilteredSearchToken } from '@gitlab/ui';
import { isEqual, pick } from 'lodash';
import { __ } from '~/locale';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from '~/graphql_shared/constants';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { createAlert } from '~/alert';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import { calculateGraphQLPaginationQueryParams } from '~/graphql_shared/utils';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { ACCESS_LEVEL_OWNER_INTEGER } from '~/access_level/constants';
import projectCountsQuery from '~/projects/your_work/graphql/queries/project_counts.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { InternalEvents } from '~/tracking';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
} from '../constants';
import userPreferencesUpdateMutation from '../graphql/mutations/user_preferences_update.mutation.graphql';
import TabView from './tab_view.vue';

const trackingMixin = InternalEvents.mixin();

// Will be made more generic to work with groups and projects in future commits
export default {
  name: 'TabsWithList',
  i18n: {
    projectCountError: __('An error occurred loading the project counts.'),
  },
  components: {
    GlTabs,
    GlTab,
    GlBadge,
    TabView,
    FilteredSearchAndSort,
  },
  mixins: [trackingMixin],
  props: {
    tabs: {
      type: Array,
      required: true,
    },
    filteredSearchSupportedTokens: {
      type: Array,
      required: false,
      default() {
        return [];
      },
    },
    filteredSearchTermKey: {
      type: String,
      required: true,
    },
    filteredSearchNamespace: {
      type: String,
      required: true,
    },
    filteredSearchRecentSearchesStorageKey: {
      type: String,
      required: true,
    },
    sortOptions: {
      type: Array,
      required: true,
    },
    defaultSortOption: {
      type: Object,
      required: true,
    },
    timestampTypeMap: {
      type: Object,
      required: true,
    },
    firstTabRouteNames: {
      type: Array,
      required: false,
      default() {
        return [];
      },
    },
    initialSort: {
      type: String,
      required: true,
    },
    programmingLanguages: {
      type: Array,
      required: false,
      default() {
        return [];
      },
    },
    eventTracking: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
  },
  data() {
    return {
      activeTabIndex: this.initActiveTabIndex(),
      counts: this.tabs.reduce((accumulator, tab) => {
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
    activeTab() {
      return this.tabs[this.activeTabIndex];
    },
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
      ].filter((filteredSearchToken) =>
        this.filteredSearchSupportedTokens.includes(filteredSearchToken.type),
      );
    },
    sortQuery() {
      return this.$route.query.sort;
    },
    sort() {
      const sortOptionValues = this.sortOptions.flatMap(({ value }) => [
        `${value}_${SORT_DIRECTION_ASC}`,
        `${value}_${SORT_DIRECTION_DESC}`,
      ]);

      if (this.sortQuery && sortOptionValues.includes(this.sortQuery)) {
        return this.sortQuery;
      }

      if (sortOptionValues.includes(this.initialSort)) {
        return this.initialSort;
      }

      return `${this.defaultSortOption.value}_${SORT_DIRECTION_ASC}`;
    },
    activeSortOption() {
      return this.sortOptions.find((sortItem) => this.sort.includes(sortItem.value));
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
        this.filteredSearchTermKey,
      ]);

      // Normalize the property to Number since Vue Router 4 will
      // return this and all other query variables as a string
      filters[FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL] = Number(
        filters[FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL],
      );

      return filters;
    },
    timestampType() {
      return this.timestampTypeMap[this.activeSortOption.value];
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
      return this.firstTabRouteNames.includes(this.$route.name)
        ? 0
        : this.tabs.findIndex((tab) => tab.value === this.$route.name);
    },
    onTabUpdate(index) {
      // This return will prevent us overwriting the root `/` and `/dashboard/projects` paths
      // when we don't need to.
      if (index === this.activeTabIndex) return;

      this.activeTabIndex = index;

      const tab = this.tabs[index] || this.tabs[0];
      this.$router.push({ name: tab.value });

      if (!this.eventTracking?.tabs) {
        return;
      }

      this.trackEvent(this.eventTracking.tabs, { label: tab.text });
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

      if (!this.eventTracking?.sort) {
        return;
      }

      this.trackEvent(this.eventTracking.sort, { label: this.activeTab.text, property: sort });
    },
    onFilter(filters) {
      const { sort } = this.$route.query;

      this.pushQuery({ sort, ...filters });

      if (!this.eventTracking?.filteredSearch) {
        return;
      }

      Object.entries(this.eventTracking.filteredSearch).forEach(([filter, event]) => {
        const filterValues = filters[filter];

        if (!filterValues) {
          return;
        }

        // Don't record the value when using text search.
        // Only record with pre-set values (e.g language or access level).
        if (filter === this.filteredSearchTermKey) {
          this.trackEvent(event, { label: this.activeTab.text });

          return;
        }

        const filteredSearchToken = this.filteredSearchTokens.find(
          (token) => token.type === filter,
        );

        if (!filteredSearchToken) {
          return;
        }

        const optionTitles = filterValues.flatMap((filterValue) => {
          const optionTitle = filteredSearchToken.options.find(
            ({ value }) => filterValue === value,
          )?.title;

          if (!optionTitle) {
            return [];
          }

          return [optionTitle];
        });

        if (!optionTitles.length) {
          return;
        }

        this.trackEvent(event, {
          label: this.activeTab.text,
          property: optionTitles.join(','),
        });
      });
    },
    onPageChange(pagination) {
      this.pushQuery(
        calculateGraphQLPaginationQueryParams({ ...pagination, routeQuery: this.$route.query }),
      );

      if (!this.eventTracking?.pagination) {
        return;
      }

      this.trackEvent(this.eventTracking.pagination, {
        label: this.activeTab.text,
        property: pagination.startCursor === null ? 'next' : 'previous',
      });
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
    <gl-tab v-for="tab in tabs" :key="tab.text" lazy>
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
        :programming-languages="programmingLanguages"
        :filtered-search-term-key="filteredSearchTermKey"
        @page-change="onPageChange"
      />
      <template v-else>{{ tab.text }}</template>
    </gl-tab>

    <template #tabs-end>
      <li class="gl-w-full">
        <filtered-search-and-sort
          class="gl-border-b-0"
          :filtered-search-namespace="filteredSearchNamespace"
          :filtered-search-tokens="filteredSearchTokens"
          :filtered-search-term-key="filteredSearchTermKey"
          :filtered-search-recent-searches-storage-key="filteredSearchRecentSearchesStorageKey"
          :filtered-search-query="$route.query"
          :is-ascending="isAscending"
          :sort-options="sortOptions"
          :active-sort-option="activeSortOption"
          @filter="onFilter"
          @sort-direction-change="onSortDirectionChange"
          @sort-by-change="onSortByChange"
        />
      </li>
    </template>
  </gl-tabs>
</template>
