<script>
import { GlTabs, GlTab, GlBadge, GlFilteredSearchToken } from '@gitlab/ui';
import { isEqual, pick, get } from 'lodash';
import { __ } from '~/locale';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from '~/graphql_shared/constants';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import { convertToCamelCase } from '~/lib/utils/text_utility';
import { createAlert } from '~/alert';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import { calculateGraphQLPaginationQueryParams } from '~/graphql_shared/utils';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  ACCESS_LEVEL_OWNER_INTEGER,
  ACCESS_LEVELS_INTEGER_TO_STRING,
} from '~/access_level/constants';
import {
  VISIBILITY_LEVEL_LABELS,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { InternalEvents } from '~/tracking';
import NamespaceToken from '~/vue_shared/components/filtered_search_bar/tokens/namespace_token.vue';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  PAGINATION_TYPE_KEYSET,
  PAGINATION_TYPE_OFFSET,
  QUERY_PARAM_PAGE,
  FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL,
  FILTERED_SEARCH_TOKEN_NAMESPACE,
} from '../constants';
import userPreferencesUpdateMutation from '../graphql/mutations/user_preferences_update.mutation.graphql';
import TabView from './tab_view.vue';

const trackingMixin = InternalEvents.mixin();

// Will be made more generic to work with groups and projects in future commits
export default {
  name: 'TabsWithList',
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
    filteredSearchInputPlaceholder: {
      type: String,
      required: false,
      default: __('Filter or search (3 character minimum)'),
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
    tabCountsQuery: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
    tabCountsQueryErrorMessage: {
      type: String,
      required: false,
      default: __('An error occurred loading the tab counts.'),
    },
    /**
     * When true, the count of the active tab is updated from the individual tab query.
     * When false, tabCountsQuery is used for all tab counts.
     */
    shouldUpdateActiveTabCountFromTabQuery: {
      type: Boolean,
      required: false,
      default: true,
    },
    paginationType: {
      type: String,
      required: true,
      validator(value) {
        return [PAGINATION_TYPE_KEYSET, PAGINATION_TYPE_OFFSET].includes(value);
      },
    },
    userPreferencesSortKey: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      activeTabIndex: this.initActiveTabIndex(),
      tabCounts: this.tabs.reduce((accumulator, tab) => {
        return {
          ...accumulator,
          [tab.value]: undefined,
        };
      }, {}),
      initialLoad: true,
    };
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
        {
          type: FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL,
          icon: 'eye',
          title: __('Visibility'),
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            VISIBILITY_LEVEL_PRIVATE_STRING,
            VISIBILITY_LEVEL_INTERNAL_STRING,
            VISIBILITY_LEVEL_PUBLIC_STRING,
          ].map((visibilityLevelString) => ({
            value: visibilityLevelString,
            title: VISIBILITY_LEVEL_LABELS[visibilityLevelString],
          })),
        },
        {
          type: FILTERED_SEARCH_TOKEN_NAMESPACE,
          icon: 'namespace',
          title: __('Namespace'),
          token: NamespaceToken,
          unique: true,
          operators: OPERATORS_IS,
          recentSuggestionsStorageKey: 'tabs-with-list-namespace',
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

      return `${this.defaultSortOption.value}_${SORT_DIRECTION_DESC}`;
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
    page() {
      return parseInt(this.$route.query[QUERY_PARAM_PAGE], 10) || 1;
    },
    routeQueryWithoutPagination() {
      const {
        [QUERY_PARAM_START_CURSOR]: startCursor,
        [QUERY_PARAM_END_CURSOR]: endCursor,
        [QUERY_PARAM_PAGE]: page,
        ...routeQuery
      } = this.$route.query;

      return routeQuery;
    },
    filters() {
      const filters = pick(this.routeQueryWithoutPagination, [
        this.filteredSearchTermKey,
        ...this.filteredSearchSupportedTokens,
      ]);

      // Normalize the property to Number since Vue Router 4 will
      // return this and all other query variables as a string
      filters[FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL] = Number(
        filters[FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL],
      );

      return filters;
    },
    search() {
      return this.filters[this.filteredSearchTermKey];
    },
    minAccessLevel() {
      const { [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: minAccessLevelInteger } = this.filters;

      return minAccessLevelInteger && ACCESS_LEVELS_INTEGER_TO_STRING[minAccessLevelInteger];
    },
    programmingLanguageName() {
      const { [FILTERED_SEARCH_TOKEN_LANGUAGE]: programmingLanguageId } = this.filters;

      return (
        programmingLanguageId &&
        this.programmingLanguages.find(({ id }) => id === parseInt(programmingLanguageId, 10))?.name
      );
    },
    namespacePath() {
      const namespacePath = this.filters[FILTERED_SEARCH_TOKEN_NAMESPACE];
      return Array.isArray(namespacePath) ? namespacePath[0] : namespacePath;
    },
    visibilityLevel() {
      const visibilityLevel = this.filters[FILTERED_SEARCH_TOKEN_VISIBILITY_LEVEL];
      return Array.isArray(visibilityLevel) ? visibilityLevel[0] : visibilityLevel;
    },
    filtersAsQueryVariables() {
      return {
        programmingLanguageName: this.programmingLanguageName,
        minAccessLevel: this.minAccessLevel,
        visibilityLevel: this.visibilityLevel,
        namespacePath: this.namespacePath,
      };
    },
    timestampType() {
      return this.timestampTypeMap[this.activeSortOption.value];
    },
    hasTabCountsQuery() {
      return Boolean(Object.keys(this.tabCountsQuery).length);
    },
  },
  async created() {
    this.getTabCounts();
  },
  methods: {
    createSortQuery({ sortBy, isAscending }) {
      return `${sortBy}_${isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC}`;
    },
    pushQuery(query) {
      if (isEqual(this.$route.query, query)) {
        return Promise.resolve();
      }

      return this.$router.push({ query });
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

      this.trackEvent(this.eventTracking.tabs, { label: tab.value });
    },
    tabCount(tab) {
      const tabCount = this.tabCounts[tab.value];

      return tabCount === undefined ? '-' : numberToMetricPrefix(tabCount);
    },
    onSortDirectionChange(isAscending) {
      const sort = this.createSortQuery({ sortBy: this.activeSortOption.value, isAscending });

      this.updateSort(sort);
    },
    onSortByChange(sortBy) {
      const sort = this.createSortQuery({ sortBy, isAscending: this.isAscending });

      this.updateSort(sort);
    },
    async updateSort(sort) {
      await this.pushQuery({ ...this.routeQueryWithoutPagination, sort });
      this.userPreferencesUpdateMutate(sort);

      if (!this.eventTracking?.sort) {
        return;
      }

      this.trackEvent(this.eventTracking.sort, { label: this.activeTab.value, property: sort });
    },
    async onFilter(filters) {
      const { sort } = this.$route.query;

      await this.pushQuery({ sort, ...filters });

      if (!this.shouldUpdateActiveTabCountFromTabQuery) {
        this.getTabCounts({ fromFilter: true });
      }

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
          this.trackEvent(event, { label: this.activeTab.value });

          return;
        }

        this.trackEvent(event, {
          label: this.activeTab.value,
          property: filterValues.join(','),
        });
      });
    },
    async onKeysetPageChange(pagination) {
      await this.pushQuery(
        calculateGraphQLPaginationQueryParams({ ...pagination, routeQuery: this.$route.query }),
      );

      if (!this.eventTracking?.pagination) {
        return;
      }

      this.trackEvent(this.eventTracking.pagination, {
        label: this.activeTab.value,
        property: pagination.startCursor === null ? 'next' : 'previous',
      });
    },
    async onOffsetPageChange(page) {
      await this.pushQuery({ ...this.$route.query, [QUERY_PARAM_PAGE]: page });
    },
    onRefetch() {
      this.getTabCounts();
    },
    async userPreferencesUpdateMutate(sort) {
      if (this.userPreferencesSortKey === null) {
        return;
      }

      try {
        await this.$apollo.mutate({
          mutation: userPreferencesUpdateMutation,
          variables: {
            input: {
              [this.userPreferencesSortKey]: sort.toUpperCase(),
            },
          },
        });
      } catch (error) {
        // Silently fail but capture exception in Sentry
        Sentry.captureException(error);
      }
    },
    skipVariableName(tab) {
      // Since GraphQL doesn't support string comparison in @skip(if:)
      // we use the naming convention of skip${tabValue} in camelCase (e.g. skipContributed).
      return convertToCamelCase(`skip_${tab.value}`);
    },
    skipVariables({ fromFilter }) {
      // Active tab is updated from individual tab query.
      // Skip fetching active tab count.
      if (this.shouldUpdateActiveTabCountFromTabQuery) {
        return { [this.skipVariableName(this.activeTab)]: true };
      }

      // This has been triggered by filtering.
      // Skip fetching all tab counts except the active tab.
      if (fromFilter) {
        return this.tabs.reduce((accumulator, tab) => {
          if (tab.value === this.activeTab.value) {
            return accumulator;
          }

          return {
            ...accumulator,
            [this.skipVariableName(tab)]: true,
          };
        }, {});
      }

      // Fetch all tab counts.
      return {};
    },
    async getTabCounts({ fromFilter = false } = {}) {
      if (!this.hasTabCountsQuery) {
        return;
      }

      try {
        const { data } = await this.$apollo.query({
          query: this.tabCountsQuery,
          variables: {
            ...this.filtersAsQueryVariables,
            search: this.search,
            ...this.skipVariables({ fromFilter }),
          },
        });

        this.tabCounts = this.tabs.reduce((accumulator, tab) => {
          const countsQueryPath = get(data, tab.countsQueryPath);
          const count =
            countsQueryPath === undefined ? this.tabCounts[tab.value] : countsQueryPath.count;

          return {
            ...accumulator,
            [tab.value]: count,
          };
        }, {});
      } catch (error) {
        createAlert({
          message: this.tabCountsQueryErrorMessage,
          error,
          captureError: true,
        });
      }
    },
    onQueryComplete() {
      if (!this.initialLoad) {
        return;
      }

      this.initialLoad = false;

      if (!this.eventTracking?.initialLoad) {
        return;
      }

      this.trackEvent(this.eventTracking.initialLoad, { label: this.activeTab.value });
    },
    onUpdateCount(tab, newCount) {
      if (!this.shouldUpdateActiveTabCountFromTabQuery) {
        return;
      }

      this.tabCounts[tab.value] = newCount;
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
            v-if="hasTabCountsQuery"
            size="sm"
            class="gl-tab-counter-badge"
            data-testid="tab-counter-badge"
          >
            {{ tabCount(tab) }}
          </gl-badge>
        </div>
      </template>

      <tab-view
        v-if="tab.query"
        :tab="tab"
        :start-cursor="startCursor"
        :end-cursor="endCursor"
        :page="page"
        :sort="sort"
        :filters="filters"
        :filters-as-query-variables="filtersAsQueryVariables"
        :search="search"
        :timestamp-type="timestampType"
        :filtered-search-term-key="filteredSearchTermKey"
        :event-tracking="eventTracking"
        :pagination-type="paginationType"
        @keyset-page-change="onKeysetPageChange"
        @offset-page-change="onOffsetPageChange"
        @refetch="onRefetch"
        @query-complete="onQueryComplete"
        @update-count="onUpdateCount"
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
          :search-input-placeholder="filteredSearchInputPlaceholder"
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
