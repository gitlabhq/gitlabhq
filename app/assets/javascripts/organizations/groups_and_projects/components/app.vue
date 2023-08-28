<script>
import { GlCollapsibleListbox, GlSorting, GlSortingItem } from '@gitlab/ui';
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
import { RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS } from '../../constants';
import {
  DISPLAY_LISTBOX_ITEMS,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_ITEMS,
  SORT_ITEM_CREATED,
  FILTERED_SEARCH_TERM_KEY,
} from '../constants';
import GroupsPage from './groups_page.vue';
import ProjectsPage from './projects_page.vue';

export default {
  i18n: {
    pageTitle: __('Groups and projects'),
    searchInputPlaceholder: s__('Organization|Search or filter list'),
    displayListboxHeaderText: __('Display'),
  },
  components: { FilteredSearchBar, GlCollapsibleListbox, GlSorting, GlSortingItem },
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
          return GroupsPage;

        case RESOURCE_TYPE_PROJECTS:
          return ProjectsPage;

        default:
          return GroupsPage;
      }
    },
    activeSortItem() {
      return this.$options.sortItems.find((sortItem) => sortItem.name === this.sortName);
    },
    sortName() {
      return this.$route.query.sort_name || SORT_ITEM_CREATED.name;
    },
    isAscending() {
      return this.$route.query.sort_direction !== SORT_DIRECTION_DESC;
    },
    sortText() {
      return this.activeSortItem.text;
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
    onSortItemClick(sortItem) {
      if (this.$route.query.sort_name === sortItem.name) {
        return;
      }

      this.pushQuery({ ...this.$route.query, sort_name: sortItem.name });
    },
    onSortDirectionChange(isAscending) {
      this.pushQuery({
        ...this.$route.query,
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
  },
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h-display">{{ $options.i18n.pageTitle }}</h1>
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
            :text="sortText"
            :is-ascending="isAscending"
            @sortDirectionChange="onSortDirectionChange"
          >
            <gl-sorting-item
              v-for="sortItem in $options.sortItems"
              :key="sortItem.name"
              :active="activeSortItem.name === sortItem.name"
              @click="onSortItemClick(sortItem)"
            >
              {{ sortItem.text }}
            </gl-sorting-item>
          </gl-sorting>
        </div>
      </div>
    </div>
    <component :is="routerView" />
  </div>
</template>
