<script>
import { GlTabs, GlTab, GlSearchBoxByType, GlSorting, GlSortingItem } from '@gitlab/ui';
import { isString, debounce } from 'lodash';
import { __ } from '~/locale';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import GroupsStore from '../store/groups_store';
import GroupsService from '../service/groups_service';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_ARCHIVED,
  OVERVIEW_TABS_SORTING_ITEMS,
} from '../constants';
import eventHub from '../event_hub';
import GroupsApp from './app.vue';
import SubgroupsAndProjectsEmptyState from './empty_states/subgroups_and_projects_empty_state.vue';
import SharedProjectsEmptyState from './empty_states/shared_projects_empty_state.vue';
import ArchivedProjectsEmptyState from './empty_states/archived_projects_empty_state.vue';

const [SORTING_ITEM_NAME] = OVERVIEW_TABS_SORTING_ITEMS;
const MIN_SEARCH_LENGTH = 3;

export default {
  components: {
    GlTabs,
    GlTab,
    GroupsApp,
    GlSearchBoxByType,
    GlSorting,
    GlSortingItem,
    SubgroupsAndProjectsEmptyState,
    SharedProjectsEmptyState,
    ArchivedProjectsEmptyState,
  },
  inject: ['endpoints', 'initialSort'],
  data() {
    const tabs = [
      {
        title: this.$options.i18n[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS],
        key: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
        emptyStateComponent: SubgroupsAndProjectsEmptyState,
        lazy: this.$route.name !== ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
        service: new GroupsService(this.endpoints[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]),
        store: new GroupsStore({ showSchemaMarkup: true }),
      },
      {
        title: this.$options.i18n[ACTIVE_TAB_SHARED],
        key: ACTIVE_TAB_SHARED,
        emptyStateComponent: SharedProjectsEmptyState,
        lazy: this.$route.name !== ACTIVE_TAB_SHARED,
        service: new GroupsService(this.endpoints[ACTIVE_TAB_SHARED]),
        store: new GroupsStore(),
      },
      {
        title: this.$options.i18n[ACTIVE_TAB_ARCHIVED],
        key: ACTIVE_TAB_ARCHIVED,
        emptyStateComponent: ArchivedProjectsEmptyState,
        lazy: this.$route.name !== ACTIVE_TAB_ARCHIVED,
        service: new GroupsService(this.endpoints[ACTIVE_TAB_ARCHIVED]),
        store: new GroupsStore(),
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
  },
  mounted() {
    this.search = this.$route.query?.filter || '';

    const sortQueryStringValue = this.$route.query?.sort || this.initialSort;
    const sort =
      OVERVIEW_TABS_SORTING_ITEMS.find((sortOption) =>
        [sortOption.asc, sortOption.desc].includes(sortQueryStringValue),
      ) || SORTING_ITEM_NAME;
    this.sort = sort;
    this.isAscending = sort.asc === sortQueryStringValue;
  },
  methods: {
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

      this.$router.push({ name: tab.key, params: { group: groupParam }, query: this.$route.query });
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
    handleSortingItemClick(sortingItem) {
      if (sortingItem === this.sort) {
        return;
      }

      this.sort = sortingItem;

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
    [ACTIVE_TAB_ARCHIVED]: __('Archived projects'),
    searchPlaceholder: __('Search'),
  },
  OVERVIEW_TABS_SORTING_ITEMS,
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
      <groups-app :action="key" :service="service" :store="store" :hide-projects="false">
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
              data-qa-selector="groups_filter_field"
              @input="handleSearchInput"
            />
          </div>
          <div class="gl-p-2 gl-w-full gl-lg-w-auto">
            <gl-sorting
              class="gl-w-full"
              dropdown-class="gl-w-full"
              data-testid="group_sort_by_dropdown"
              :text="sort.label"
              :is-ascending="isAscending"
              @sortDirectionChange="handleSortDirectionChange"
            >
              <gl-sorting-item
                v-for="sortingItem in $options.OVERVIEW_TABS_SORTING_ITEMS"
                :key="sortingItem.label"
                :active="sortingItem === sort"
                @click="handleSortingItemClick(sortingItem)"
                >{{ sortingItem.label }}</gl-sorting-item
              >
            </gl-sorting>
          </div>
        </div>
      </li>
    </template>
  </gl-tabs>
</template>
