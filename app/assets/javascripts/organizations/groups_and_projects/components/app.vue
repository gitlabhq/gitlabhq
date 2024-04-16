<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { __ } from '~/locale';
import { RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS } from '~/organizations/constants';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import ProjectsView from '~/organizations/shared/components/projects_view.vue';
import NewGroupButton from '~/organizations/shared/components/new_group_button.vue';
import NewProjectButton from '~/organizations/shared/components/new_project_button.vue';
import { onPageChange } from '~/organizations/shared/utils';
import {
  QUERY_PARAM_END_CURSOR,
  QUERY_PARAM_START_CURSOR,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_ITEM_NAME,
} from '~/organizations/shared/constants';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import {
  RECENT_SEARCHES_STORAGE_KEY_GROUPS,
  RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
} from '~/filtered_search/recent_searches_storage_keys';
import {
  DISPLAY_LISTBOX_ITEMS,
  SORT_ITEMS,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
} from '../constants';

export default {
  i18n: {
    pageTitle: __('Groups and projects'),
    displayListboxHeaderText: __('Display'),
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
  computed: {
    displayQuery() {
      const { display } = this.$route.query;

      return display;
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
      return this.$route.query.sort_name || SORT_ITEM_NAME.value;
    },
    sortDirection() {
      return this.$route.query.sort_direction || SORT_DIRECTION_ASC;
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
      const { display } = this.$route.query;

      return [RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS].includes(display)
        ? display
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
    pushQuery(query) {
      const currentQuery = this.$route.query;

      if (isEqual(currentQuery, query)) {
        return;
      }

      this.$router.push({ query });
    },
    onDisplayListboxSelect(display) {
      this.pushQuery({ display });
    },
    onSortByChange(sortValue) {
      if (this.$route.query.sort_name === sortValue) {
        return;
      }

      this.pushQuery({ ...this.routeQueryWithoutPagination, sort_name: sortValue });
    },
    onSortDirectionChange(isAscending) {
      this.pushQuery({
        ...this.routeQueryWithoutPagination,
        sort_direction: isAscending ? SORT_DIRECTION_ASC : SORT_DIRECTION_DESC,
      });
    },
    onFilter(filters) {
      const { display, sort_name, sort_direction } = this.$route.query;

      this.pushQuery({
        display,
        sort_name,
        sort_direction,
        ...filters,
      });
    },
    onPageChange(pagination) {
      this.pushQuery(onPageChange({ ...pagination, routeQuery: this.$route.query }));
    },
  },
};
</script>

<template>
  <div>
    <div
      class="page-title-holder gl-display-flex gl-sm-flex-direction-row gl-flex-direction-column gl-sm-align-items-center"
    >
      <h1 class="page-title gl-font-size-h-display">{{ $options.i18n.pageTitle }}</h1>
      <div class="gl-display-flex gl-column-gap-3 gl-sm-ml-auto gl-mb-4 gl-sm-mb-0">
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
      @filter="onFilter"
      @sort-direction-change="onSortDirectionChange"
      @sort-by-change="onSortByChange"
    >
      <gl-collapsible-listbox
        :selected="displayListboxSelected"
        :items="$options.displayListboxItems"
        :header-text="$options.i18n.displayListboxHeaderText"
        block
        toggle-class="gl-md-w-30"
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
