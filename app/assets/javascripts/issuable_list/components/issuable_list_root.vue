<script>
import { GlLoadingIcon, GlPagination } from '@gitlab/ui';

import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

import IssuableTabs from './issuable_tabs.vue';
import IssuableItem from './issuable_item.vue';

export default {
  components: {
    GlLoadingIcon,
    IssuableTabs,
    FilteredSearchBar,
    IssuableItem,
    GlPagination,
  },
  props: {
    namespace: {
      type: String,
      required: true,
    },
    recentSearchesStorageKey: {
      type: String,
      required: true,
    },
    searchInputPlaceholder: {
      type: String,
      required: true,
    },
    searchTokens: {
      type: Array,
      required: true,
    },
    sortOptions: {
      type: Array,
      required: true,
    },
    initialFilterValue: {
      type: Array,
      required: false,
      default: () => [],
    },
    initialSortBy: {
      type: String,
      required: false,
      default: 'created_desc',
    },
    issuables: {
      type: Array,
      required: true,
    },
    tabs: {
      type: Array,
      required: true,
    },
    tabCounts: {
      type: Object,
      required: true,
    },
    currentTab: {
      type: String,
      required: true,
    },
    issuableSymbol: {
      type: String,
      required: false,
      default: '#',
    },
    issuablesLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    showPaginationControls: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultPageSize: {
      type: Number,
      required: false,
      default: 20,
    },
    currentPage: {
      type: Number,
      required: false,
      default: 1,
    },
    previousPage: {
      type: Number,
      required: false,
      default: 0,
    },
    nextPage: {
      type: Number,
      required: false,
      default: 2,
    },
  },
};
</script>

<template>
  <div class="issuable-list-container">
    <issuable-tabs
      :tabs="tabs"
      :tab-counts="tabCounts"
      :current-tab="currentTab"
      @click="$emit('click-tab', $event)"
    >
      <template #nav-actions>
        <slot name="nav-actions"></slot>
      </template>
    </issuable-tabs>
    <filtered-search-bar
      :namespace="namespace"
      :recent-searches-storage-key="recentSearchesStorageKey"
      :search-input-placeholder="searchInputPlaceholder"
      :tokens="searchTokens"
      :sort-options="sortOptions"
      :initial-filter-value="initialFilterValue"
      :initial-sort-by="initialSortBy"
      class="gl-flex-grow-1 row-content-block"
      @onFilter="$emit('filter', $event)"
      @onSort="$emit('sort', $event)"
    />
    <div class="issuables-holder">
      <gl-loading-icon v-if="issuablesLoading" size="md" class="gl-mt-5" />
      <ul
        v-if="!issuablesLoading && issuables.length"
        class="content-list issuable-list issues-list"
      >
        <issuable-item
          v-for="issuable in issuables"
          :key="issuable.id"
          :issuable-symbol="issuableSymbol"
          :issuable="issuable"
        />
      </ul>
      <slot v-if="!issuablesLoading && !issuables.length" name="empty-state"></slot>
      <gl-pagination
        v-if="showPaginationControls"
        :per-page="defaultPageSize"
        :value="currentPage"
        :prev-page="previousPage"
        :next-page="nextPage"
        align="center"
        class="gl-pagination gl-mt-3"
        @input="$emit('page-change', $event)"
      />
    </div>
  </div>
</template>
