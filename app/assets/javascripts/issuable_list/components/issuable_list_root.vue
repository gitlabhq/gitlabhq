<script>
import { GlKeysetPagination, GlSkeletonLoading, GlPagination } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

import { DEFAULT_SKELETON_COUNT } from '../constants';
import IssuableBulkEditSidebar from './issuable_bulk_edit_sidebar.vue';
import IssuableItem from './issuable_item.vue';
import IssuableTabs from './issuable_tabs.vue';

const VueDraggable = () => import('vuedraggable');

export default {
  vueDraggableAttributes: {
    animation: 200,
    ghostClass: 'gl-visibility-hidden',
    tag: 'ul',
  },
  components: {
    GlKeysetPagination,
    GlSkeletonLoading,
    IssuableTabs,
    FilteredSearchBar,
    IssuableItem,
    IssuableBulkEditSidebar,
    GlPagination,
    VueDraggable,
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
    urlParams: {
      type: Object,
      required: false,
      default: () => ({}),
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
      required: false,
      default: null,
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
    showBulkEditSidebar: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultPageSize: {
      type: Number,
      required: false,
      default: 20,
    },
    totalItems: {
      type: Number,
      required: false,
      default: 0,
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
    enableLabelPermalinks: {
      type: Boolean,
      required: false,
      default: true,
    },
    labelFilterParam: {
      type: String,
      required: false,
      default: undefined,
    },
    isManualOrdering: {
      type: Boolean,
      required: false,
      default: false,
    },
    useKeysetPagination: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasNextPage: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasPreviousPage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      checkedIssuables: {},
    };
  },
  computed: {
    skeletonItemCount() {
      const { totalItems, defaultPageSize, currentPage } = this;
      const totalPages = Math.ceil(totalItems / defaultPageSize);

      if (totalPages) {
        return currentPage < totalPages
          ? defaultPageSize
          : totalItems % defaultPageSize || defaultPageSize;
      }
      return DEFAULT_SKELETON_COUNT;
    },
    allIssuablesChecked() {
      return this.bulkEditIssuables.length === this.issuables.length;
    },
    /**
     * Returns all the checked issuables from `checkedIssuables` map.
     */
    bulkEditIssuables() {
      return Object.keys(this.checkedIssuables).reduce((acc, issuableId) => {
        if (this.checkedIssuables[issuableId].checked) {
          acc.push(this.checkedIssuables[issuableId].issuable);
        }
        return acc;
      }, []);
    },
    issuablesWrapper() {
      return this.isManualOrdering ? VueDraggable : 'ul';
    },
  },
  watch: {
    issuables(list) {
      this.checkedIssuables = list.reduce((acc, issuable) => {
        const id = this.issuableId(issuable);
        acc[id] = {
          // By default, an issuable is not checked,
          // But if `checkedIssuables` is already
          // populated, use existing value.
          checked:
            typeof this.checkedIssuables[id] !== 'boolean'
              ? false
              : this.checkedIssuables[id].checked,
          // We're caching issuable reference here
          // for ease of populating in `bulkEditIssuables`.
          issuable,
        };
        return acc;
      }, {});
    },
    urlParams: {
      deep: true,
      immediate: true,
      handler(params) {
        if (Object.keys(params).length) {
          updateHistory({
            url: setUrlParams(params, window.location.href, true, false, true),
            title: document.title,
            replace: true,
          });
        }
      },
    },
  },
  methods: {
    issuableId(issuable) {
      return getIdFromGraphQLId(issuable.id) || issuable.iid || uniqueId();
    },
    issuableChecked(issuable) {
      return this.checkedIssuables[this.issuableId(issuable)]?.checked;
    },
    handleIssuableCheckedInput(issuable, value) {
      this.checkedIssuables[this.issuableId(issuable)].checked = value;
      this.$emit('update-legacy-bulk-edit');
    },
    handleAllIssuablesCheckedInput(value) {
      Object.keys(this.checkedIssuables).forEach((issuableId) => {
        this.checkedIssuables[issuableId].checked = value;
      });
      this.$emit('update-legacy-bulk-edit');
    },
    handleVueDraggableUpdate({ newIndex, oldIndex }) {
      this.$emit('reorder', { newIndex, oldIndex });
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
      :show-checkbox="showBulkEditSidebar"
      :checkbox-checked="allIssuablesChecked"
      class="gl-flex-grow-1 gl-border-t-none row-content-block"
      @checked-input="handleAllIssuablesCheckedInput"
      @onFilter="$emit('filter', $event)"
      @onSort="$emit('sort', $event)"
    />
    <issuable-bulk-edit-sidebar :expanded="showBulkEditSidebar">
      <template #bulk-edit-actions>
        <slot name="bulk-edit-actions" :checked-issuables="bulkEditIssuables"></slot>
      </template>
      <template #sidebar-items>
        <slot name="sidebar-items" :checked-issuables="bulkEditIssuables"></slot>
      </template>
    </issuable-bulk-edit-sidebar>
    <div class="issuables-holder">
      <ul v-if="issuablesLoading" class="content-list">
        <li v-for="n in skeletonItemCount" :key="n" class="issue gl-px-5! gl-py-5!">
          <gl-skeleton-loading />
        </li>
      </ul>
      <template v-else>
        <component
          :is="issuablesWrapper"
          v-if="issuables.length > 0"
          class="content-list issuable-list issues-list"
          :class="{ 'manual-ordering': isManualOrdering }"
          v-bind="$options.vueDraggableAttributes"
          @update="handleVueDraggableUpdate"
        >
          <issuable-item
            v-for="issuable in issuables"
            :key="issuableId(issuable)"
            :class="{ 'gl-cursor-grab': isManualOrdering }"
            :issuable-symbol="issuableSymbol"
            :issuable="issuable"
            :enable-label-permalinks="enableLabelPermalinks"
            :label-filter-param="labelFilterParam"
            :show-checkbox="showBulkEditSidebar"
            :checked="issuableChecked(issuable)"
            @checked-input="handleIssuableCheckedInput(issuable, $event)"
          >
            <template #reference>
              <slot name="reference" :issuable="issuable"></slot>
            </template>
            <template #author>
              <slot name="author" :author="issuable.author"></slot>
            </template>
            <template #timeframe>
              <slot name="timeframe" :issuable="issuable"></slot>
            </template>
            <template #status>
              <slot name="status" :issuable="issuable"></slot>
            </template>
            <template #statistics>
              <slot name="statistics" :issuable="issuable"></slot>
            </template>
          </issuable-item>
        </component>
        <slot v-else name="empty-state"></slot>
      </template>

      <div v-if="showPaginationControls && useKeysetPagination" class="gl-text-center gl-mt-3">
        <gl-keyset-pagination
          :has-next-page="hasNextPage"
          :has-previous-page="hasPreviousPage"
          @next="$emit('next-page')"
          @prev="$emit('previous-page')"
        />
      </div>
      <gl-pagination
        v-else-if="showPaginationControls"
        :per-page="defaultPageSize"
        :total-items="totalItems"
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
