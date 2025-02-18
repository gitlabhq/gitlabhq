<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { isEqual, inRange } from 'lodash';
import { __ } from '~/locale';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import ProjectsView from '~/organizations/shared/components/projects_view.vue';
import NewGroupButton from '~/organizations/shared/components/new_group_button.vue';
import NewProjectButton from '~/organizations/shared/components/new_project_button.vue';
import { calculateGraphQLPaginationQueryParams } from '~/graphql_shared/utils';
import {
  RESOURCE_TYPE_GROUPS,
  RESOURCE_TYPE_PROJECTS,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_ITEM_NAME,
} from '~/organizations/shared/constants';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from '~/graphql_shared/constants';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import {
  RECENT_SEARCHES_STORAGE_KEY_GROUPS,
  RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
} from '~/filtered_search/recent_searches_storage_keys';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import userPreferencesUpdate from '../graphql/mutations/user_preferences_update.mutation.graphql';
import {
  DISPLAY_LISTBOX_ITEMS,
  SORT_ITEMS,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  SORT_ITEMS_GRAPHQL_ENUMS,
} from '../constants';

export default {
  i18n: {
    pageTitle: __('Groups and projects'),
    displayListboxHeaderText: __('Display'),
    filteredSearchPlaceholder: __('Search (3 character minimum)'),
  },
  components: {
    FilteredSearchAndSort,
    GlCollapsibleListbox,
    NewGroupButton,
    NewProjectButton,
  },
  filteredSearch: {
    tokens: [],
    namespace: FILTERED_SEARCH_NAMESPACE,
    searchTermKey: FILTERED_SEARCH_TERM_KEY,
  },
  displayListboxItems: DISPLAY_LISTBOX_ITEMS,
  sortItems: SORT_ITEMS,
  inject: ['userPreferenceSortName', 'userPreferenceSortDirection', 'userPreferenceDisplay'],
  computed: {
    displayQuery() {
      const { display } = this.$route.query;

      return display || this.userPreferenceDisplay;
    },
    routerView() {
      switch (this.displayQuery) {
        case RESOURCE_TYPE_GROUPS:
          return GroupsView;

        case RESOURCE_TYPE_PROJECTS:
          return ProjectsView;

        default:
          return GroupsView;
      }
    },
    filteredSearchRecentSearchesStorageKey() {
      switch (this.displayQuery) {
        case RESOURCE_TYPE_GROUPS:
          return RECENT_SEARCHES_STORAGE_KEY_GROUPS;

        case RESOURCE_TYPE_PROJECTS:
          return RECENT_SEARCHES_STORAGE_KEY_PROJECTS;

        default:
          return RECENT_SEARCHES_STORAGE_KEY_GROUPS;
      }
    },
    activeSortItem() {
      return (
        this.$options.sortItems.find((sortItem) => sortItem.value === this.sortName) ||
        SORT_ITEM_NAME
      );
    },
    sortName() {
      return this.$route.query.sort_name || this.userPreferenceSortName;
    },
    sortDirection() {
      return this.$route.query.sort_direction || this.userPreferenceSortDirection;
    },
    isAscending() {
      return this.sortDirection !== SORT_DIRECTION_DESC;
    },
    sortText() {
      return this.activeSortItem.text;
    },
    startCursor() {
      return this.$route.query[QUERY_PARAM_START_CURSOR] || null;
    },
    endCursor() {
      return this.$route.query[QUERY_PARAM_END_CURSOR] || null;
    },
    displayListboxSelected() {
      return [RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS].includes(this.displayQuery)
        ? this.displayQuery
        : RESOURCE_TYPE_GROUPS;
    },
    search() {
      return this.$route.query[FILTERED_SEARCH_TERM_KEY] || '';
    },
    routeQueryWithoutPagination() {
      const {
        [QUERY_PARAM_START_CURSOR]: startCursor,
        [QUERY_PARAM_END_CURSOR]: endCursor,
        ...routeQuery
      } = this.$route.query;

      return routeQuery;
    },
  },
  methods: {
    async pushQuery(query) {
      const currentQuery = this.$route.query;

      if (isEqual(currentQuery, query)) {
        return;
      }

      await this.$router.push({ query });
    },
    onDisplayListboxSelect(display) {
      this.pushQuery({ display });
      this.userPreferencesUpdateMutate({
        organizationGroupsProjectsDisplay: display.toUpperCase(),
      });
    },
    async onSortByChange(sortName) {
      if (this.$route.query.sort_name === sortName) {
        return;
      }

      await this.pushQuery({ ...this.routeQueryWithoutPagination, sort_name: sortName });
      this.userPreferencesUpdateSort();
    },
    async onSortDirectionChange(isAscending) {
      await this.pushQuery({
        ...this.routeQueryWithoutPagination,
        sort_direction: isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC,
      });
      this.userPreferencesUpdateSort();
    },
    onFilter(filters) {
      const { display, sort_name, sort_direction } = this.$route.query;
      const { [FILTERED_SEARCH_TERM_KEY]: search = '' } = filters;

      // API requires search to be 3 characters
      // Don't search if length is between 1 and 3 characters
      if (inRange(search.length, 1, 3)) {
        return;
      }

      this.pushQuery({
        display,
        sort_name,
        sort_direction,
        ...filters,
      });
    },
    onPageChange(pagination) {
      this.pushQuery(
        calculateGraphQLPaginationQueryParams({ ...pagination, routeQuery: this.$route.query }),
      );
    },
    async userPreferencesUpdateMutate(input) {
      try {
        await this.$apollo.mutate({
          mutation: userPreferencesUpdate,
          variables: {
            input,
          },
        });
      } catch (error) {
        // Silently fail but capture exception in Sentry
        Sentry.captureException(error);
      }
    },
    userPreferencesUpdateSort() {
      const sortGraphQLEnum = SORT_ITEMS_GRAPHQL_ENUMS[this.sortName];

      if (!sortGraphQLEnum) {
        return;
      }

      const direction = this.isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC;

      this.userPreferencesUpdateMutate({
        organizationGroupsProjectsSort: `${sortGraphQLEnum}_${direction.toUpperCase()}`,
      });
    },
  },
};
</script>

<template>
  <div>
    <div class="page-title-holder gl-flex gl-flex-col sm:gl-flex-row sm:gl-items-center">
      <h1 class="page-title gl-text-size-h-display">{{ $options.i18n.pageTitle }}</h1>
      <div class="gl-mb-4 gl-flex gl-gap-x-3 sm:gl-mb-0 sm:gl-ml-auto">
        <new-group-button category="secondary" />
        <new-project-button />
      </div>
    </div>
    <filtered-search-and-sort
      :filtered-search-namespace="$options.filteredSearch.namespace"
      :filtered-search-tokens="$options.filteredSearch.tokens"
      :filtered-search-term-key="$options.filteredSearch.searchTermKey"
      :filtered-search-query="$route.query"
      :filtered-search-recent-searches-storage-key="filteredSearchRecentSearchesStorageKey"
      :is-ascending="isAscending"
      :sort-options="$options.sortItems"
      :active-sort-option="activeSortItem"
      :search-input-placeholder="$options.i18n.filteredSearchPlaceholder"
      @filter="onFilter"
      @sort-direction-change="onSortDirectionChange"
      @sort-by-change="onSortByChange"
    >
      <gl-collapsible-listbox
        :selected="displayListboxSelected"
        :items="$options.displayListboxItems"
        :header-text="$options.i18n.displayListboxHeaderText"
        block
        toggle-class="md:gl-w-30"
        @select="onDisplayListboxSelect"
      />
    </filtered-search-and-sort>
    <component
      :is="routerView"
      list-item-class="gl-px-5"
      :start-cursor="startCursor"
      :end-cursor="endCursor"
      :search="search"
      :sort-name="sortName"
      :sort-direction="sortDirection"
      @page-change="onPageChange"
    />
  </div>
</template>
