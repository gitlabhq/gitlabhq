<script>
import { GlTabs, GlTab, GlSearchBoxByType, GlSorting } from '@gitlab/ui';
import { isString, debounce } from 'lodash';
import { __ } from '~/locale';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import { markRaw } from '~/lib/utils/vue3compat/mark_raw';
import GroupsStore from '../store/groups_store';
import GroupsService from '../service/groups_service';
import InactiveProjectsService from '../service/inactive_projects_service';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_INACTIVE,
  SORTING_ITEM_NAME,
  OVERVIEW_TABS_SORTING_ITEMS,
  OVERVIEW_TABS_ARCHIVED_PROJECTS_SORTING_ITEMS,
} from '../constants';
import eventHub from '../event_hub';
import GroupsApp from './app.vue';
import SubgroupsAndProjectsEmptyState from './empty_states/subgroups_and_projects_empty_state.vue';
import SharedProjectsEmptyState from './empty_states/shared_projects_empty_state.vue';
import InactiveProjectsEmptyState from './empty_states/inactive_projects_empty_state.vue';

const MIN_SEARCH_LENGTH = 3;

export default {
  components: {
    GlTabs,
    GlTab,
    GroupsApp,
    GlSearchBoxByType,
    GlSorting,
    SubgroupsAndProjectsEmptyState,
    SharedProjectsEmptyState,
    InactiveProjectsEmptyState,
  },
  inject: ['endpoints', 'initialSort', 'groupId'],
  data() {
    const tabs = [
      {
        title: this.$options.i18n[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS],
        key: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
        emptyStateComponent: markRaw(SubgroupsAndProjectsEmptyState),
        lazy: this.$route.name !== ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
        service: new GroupsService(
          this.endpoints[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS],
          this.initialSort,
        ),
        store: new GroupsStore({ showSchemaMarkup: true }),
        sortingItems: OVERVIEW_TABS_SORTING_ITEMS,
      },
      {
        title: this.$options.i18n[ACTIVE_TAB_SHARED],
        key: ACTIVE_TAB_SHARED,
        emptyStateComponent: markRaw(SharedProjectsEmptyState),
        lazy: this.$route.name !== ACTIVE_TAB_SHARED,
        service: new GroupsService(this.endpoints[ACTIVE_TAB_SHARED], this.initialSort),
        store: new GroupsStore(),
        sortingItems: OVERVIEW_TABS_SORTING_ITEMS,
      },
      {
        title: this.$options.i18n[ACTIVE_TAB_INACTIVE],
        key: ACTIVE_TAB_INACTIVE,
        emptyStateComponent: markRaw(InactiveProjectsEmptyState),
        lazy: this.$route.name !== ACTIVE_TAB_INACTIVE,
        service: new InactiveProjectsService(this.groupId, this.initialSort),
        store: new GroupsStore(),
        sortingItems: OVERVIEW_TABS_ARCHIVED_PROJECTS_SORTING_ITEMS,
      },
    ];
    return {
      tabs,
      activeTabIndex: tabs.findIndex((tab) => tab.key === this.$route.name),
      sort: SORTING_ITEM_NAME,
      isAscending: true,
      search: '',
    };
  },
  computed: {
    activeTab() {
      return this.tabs[this.activeTabIndex];
    },
    sortQueryStringValue() {
      return this.isAscending ? this.sort.asc : this.sort.desc;
    },
    activeTabSortOptions() {
      return this.activeTab.sortingItems.map(({ label }) => ({ value: label, text: label }));
    },
  },
  mounted() {
    this.search = this.$route.query?.filter || '';

    const { sort, isAscending } = this.getActiveSort();

    this.sort = sort;
    this.isAscending = isAscending;
  },
  methods: {
    getActiveSort() {
      const sortQueryStringValue = this.$route.query?.sort || this.initialSort;
      const sort = this.activeTab.sortingItems.find((sortOption) =>
        [sortOption.asc, sortOption.desc].includes(sortQueryStringValue),
      );

      if (!sort) {
        return {
          sort: SORTING_ITEM_NAME,
          isAscending: true,
        };
      }

      return {
        sort,
        isAscending: sort.asc === sortQueryStringValue,
      };
    },
    handleTabInput(tabIndex) {
      if (tabIndex === this.activeTabIndex) {
        return;
      }

      this.activeTabIndex = tabIndex;

      const tab = this.tabs[tabIndex];
      tab.lazy = false;

      // Vue router will convert `/` to `%2F` if you pass a string as a param
      // If you pass an array as a param it will concatenate them with a `/`
      // This makes sure we are always passing an array for the group param
      const groupParam = isString(this.$route.params.group)
        ? this.$route.params.group.split('/')
        : this.$route.params.group;

      const { sort, isAscending } = this.getActiveSort();

      this.sort = sort;
      this.isAscending = isAscending;

      const sortQuery = isAscending ? sort.asc : sort.desc;

      const query = {
        ...this.$route.query,
        ...(this.$route.query?.sort && { sort: sortQuery }),
      };

      this.$router.push({
        name: tab.key,
        params: { group: groupParam },
        query,
      });
    },
    handleSearchOrSortChange() {
      // Update query string
      const query = {};
      if (this.sortQueryStringValue !== this.initialSort) {
        query.sort = this.isAscending ? this.sort.asc : this.sort.desc;
      }
      if (this.search) {
        query.filter = this.search;
      }
      this.$router.push({ query });

      // Reset `lazy` prop so that groups/projects are fetched with updated `sort` and `filter` params when switching tabs
      this.tabs.forEach((tab, index) => {
        if (index === this.activeTabIndex) {
          return;
        }
        // eslint-disable-next-line no-param-reassign
        tab.lazy = true;
      });

      // Update data
      eventHub.$emit(`${this.activeTab.key}fetchFilteredAndSortedGroups`, {
        filterGroupsBy: this.search,
        sortBy: this.sortQueryStringValue,
      });
    },
    handleSortDirectionChange() {
      this.isAscending = !this.isAscending;

      this.handleSearchOrSortChange();
    },
    handleSortingItemClick(value) {
      const selectedSortingItem = this.activeTab.sortingItems.find((item) => item.label === value);

      if (selectedSortingItem === this.sort) {
        return;
      }

      this.sort = selectedSortingItem;

      this.handleSearchOrSortChange();
    },
    handleSearchInput(value) {
      this.search = value;

      if (!this.search || this.search.length >= MIN_SEARCH_LENGTH) {
        this.debouncedSearch();
      }
    },
    debouncedSearch: debounce(async function debouncedSearch() {
      this.handleSearchOrSortChange();
    }, DEBOUNCE_DELAY),
  },
  i18n: {
    [ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]: __('Subgroups and projects'),
    [ACTIVE_TAB_SHARED]: __('Shared projects'),
    [ACTIVE_TAB_INACTIVE]: __('Inactive'),
    searchPlaceholder: __('Search'),
  },
};
</script>

<template>
  <gl-tabs content-class="gl-pt-0" :value="activeTabIndex" @input="handleTabInput">
    <gl-tab
      v-for="{ key, title, emptyStateComponent, lazy, service, store } in tabs"
      :key="key"
      :title="title"
      :lazy="lazy"
    >
      <groups-app :action="key" :service="service" :store="store">
        <template v-if="emptyStateComponent" #empty-state>
          <component :is="emptyStateComponent" />
        </template>
      </groups-app>
    </gl-tab>
    <template #tabs-end>
      <li class="gl-flex-grow-1 gl-align-self-center gl-w-full gl-lg-w-auto gl-py-2">
        <div class="gl-lg-display-flex gl-justify-content-end gl-mx-n2 gl-my-n2">
          <div class="gl-p-2 gl-lg-form-input-md gl-w-full">
            <gl-search-box-by-type
              :value="search"
              :placeholder="$options.i18n.searchPlaceholder"
              data-testid="groups-filter-field"
              @input="handleSearchInput"
            />
          </div>
          <div class="gl-p-2 gl-w-full gl-lg-w-auto">
            <gl-sorting
              class="gl-w-full"
              dropdown-class="gl-w-full"
              data-testid="group_sort_by_dropdown"
              block
              :text="sort.label"
              :is-ascending="isAscending"
              :sort-options="activeTabSortOptions"
              :sort-by="sort.label"
              @sortByChange="handleSortingItemClick"
              @sortDirectionChange="handleSortDirectionChange"
            />
          </div>
        </div>
      </li>
    </template>
  </gl-tabs>
</template>
