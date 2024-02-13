<script>
import { GlCollapsibleListbox, GlSorting } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { s__, __ } from '~/locale';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  filterToQueryObject,
  processFilters,
  urlQueryToFilter,
  prepareTokens,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_EMPTY_SEARCH_TERM,
} from '~/vue_shared/components/filtered_search_bar/constants';
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
import { DISPLAY_LISTBOX_ITEMS, SORT_ITEMS, FILTERED_SEARCH_TERM_KEY } from '../constants';

export default {
  i18n: {
    pageTitle: __('Groups and projects'),
    searchInputPlaceholder: s__('Organization|Search or filter list'),
    displayListboxHeaderText: __('Display'),
  },
  components: {
    FilteredSearchBar,
    GlCollapsibleListbox,
    GlSorting,
    NewGroupButton,
    NewProjectButton,
  },
  filteredSearch: {
    tokens: [],
    namespace: 'organization_groups_and_projects',
    recentSearchesStorageKey: 'organization_groups_and_projects',
  },
  displayListboxItems: DISPLAY_LISTBOX_ITEMS,
  sortItems: SORT_ITEMS,
  computed: {
    routerView() {
      const { display } = this.$route.query;

      switch (display) {
        case RESOURCE_TYPE_GROUPS:
          return GroupsView;

        case RESOURCE_TYPE_PROJECTS:
          return ProjectsView;

        default:
          return GroupsView;
      }
    },
    activeSortItem() {
      return this.$options.sortItems.find((sortItem) => sortItem.value === this.sortName);
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
    filteredSearchValue() {
      const tokens = prepareTokens(
        urlQueryToFilter(this.$route.query, {
          filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
          filterNamesAllowList: [FILTERED_SEARCH_TERM],
        }),
      );

      return tokens.length ? tokens : [TOKEN_EMPTY_SEARCH_TERM];
    },
    displayListboxSelected() {
      const { display } = this.$route.query;

      return [RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS].includes(display)
        ? display
        : RESOURCE_TYPE_GROUPS;
    },
    search() {
      return (
        this.filteredSearchValue.find((token) => token.type === FILTERED_SEARCH_TERM)?.value
          ?.data || ''
      );
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
    onSortItemClick(sortValue) {
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
        ...filterToQueryObject(processFilters(filters), {
          filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
        }),
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
    <div class="gl-p-5 gl-bg-gray-10 gl-border-t gl-border-b">
      <div class="gl-mx-n2 gl-my-n2 gl-md-display-flex">
        <div class="gl-p-2 gl-flex-grow-1">
          <filtered-search-bar
            :namespace="$options.filteredSearch.namespace"
            :tokens="$options.filteredSearch.tokens"
            :initial-filter-value="filteredSearchValue"
            sync-filter-and-sort
            :recent-searches-storage-key="$options.filteredSearch.recentSearchesStorageKey"
            :search-input-placeholder="$options.i18n.searchInputPlaceholder"
            @onFilter="onFilter"
          />
        </div>
        <div class="gl-p-2">
          <gl-collapsible-listbox
            :selected="displayListboxSelected"
            :items="$options.displayListboxItems"
            :header-text="$options.i18n.displayListboxHeaderText"
            block
            toggle-class="gl-md-w-30"
            @select="onDisplayListboxSelect"
          />
        </div>
        <div class="gl-p-2">
          <gl-sorting
            class="gl-display-flex"
            dropdown-class="gl-w-full"
            block
            :text="sortText"
            :is-ascending="isAscending"
            :sort-options="$options.sortItems"
            :sort-by="activeSortItem.value"
            @sortDirectionChange="onSortDirectionChange"
            @sortByChange="onSortItemClick"
          />
        </div>
      </div>
    </div>
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
