<script>
import { GlAlert, GlBadge, GlKeysetPagination, GlSkeletonLoader, GlPagination } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { DRAG_DELAY } from '~/sortable/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import issuableEventHub from '~/issues/list/eventhub';
import { DEFAULT_SKELETON_COUNT, PAGE_SIZE_STORAGE_KEY } from '../constants';
import IssuableBulkEditSidebar from './issuable_bulk_edit_sidebar.vue';
import IssuableItem from './issuable_item.vue';
import IssuableTabs from './issuable_tabs.vue';
import IssuableGrid from './issuable_grid.vue';

const VueDraggable = () => import('vuedraggable');

export default {
  vueDraggableAttributes: {
    animation: 200,
    forceFallback: true,
    ghostClass: 'gl-visibility-hidden',
    tag: 'ul',
    delay: DRAG_DELAY,
    delayOnTouchOnly: true,
  },
  components: {
    GlAlert,
    GlBadge,
    GlKeysetPagination,
    GlSkeletonLoader,
    IssuableTabs,
    FilteredSearchBar,
    IssuableItem,
    IssuableGrid,
    IssuableBulkEditSidebar,
    GlPagination,
    VueDraggable,
    PageSizeSelector,
    LocalStorageSync,
  },
  mixins: [glFeatureFlagMixin()],
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
      required: false,
      default: __('Search or filter results…'),
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
    truncateCounts: {
      type: Boolean,
      required: false,
      default: false,
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
    hasScopedLabelsFeature: {
      type: Boolean,
      required: false,
      default: false,
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
    error: {
      type: String,
      required: false,
      default: '',
    },
    syncFilterAndSort: {
      type: Boolean,
      required: false,
      default: false,
    },
    showFilteredSearchFriendlyText: {
      type: Boolean,
      required: false,
      default: false,
    },
    showPageSizeChangeControls: {
      type: Boolean,
      required: false,
      default: false,
    },
    showWorkItemTypeIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGridView: {
      type: Boolean,
      required: false,
      default: false,
    },
    activeIssuable: {
      type: Object,
      required: false,
      default: null,
    },
    preventRedirect: {
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
    gridViewFeatureEnabled() {
      return Boolean(this.glFeatures?.issuesGridView);
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
      issuableEventHub.$emit('issuables:issuableChecked', issuable, value);
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
    handlePageSizeChange(newPageSize) {
      this.$emit('page-size-change', newPageSize);
    },
    isIssuableActive(issuable) {
      return Boolean(issuable.iid === this.activeIssuable?.iid);
    },
  },
  PAGE_SIZE_STORAGE_KEY,
};
</script>

<template>
  <div class="issuable-list-container">
    <issuable-tabs
      :tabs="tabs"
      :tab-counts="tabCounts"
      :current-tab="currentTab"
      :truncate-counts="truncateCounts"
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
      :sync-filter-and-sort="syncFilterAndSort"
      :show-checkbox="showBulkEditSidebar"
      :checkbox-checked="allIssuablesChecked"
      :show-friendly-text="showFilteredSearchFriendlyText"
      terms-as-tokens
      class="gl-flex-grow-1 gl-border-t-none row-content-block"
      data-testid="issuable-search-container"
      @checked-input="handleAllIssuablesCheckedInput"
      @onFilter="$emit('filter', $event)"
      @onSort="$emit('sort', $event)"
    />
    <gl-alert v-if="error" variant="danger" @dismiss="$emit('dismiss-alert')">{{ error }}</gl-alert>
    <issuable-bulk-edit-sidebar :expanded="showBulkEditSidebar">
      <template #bulk-edit-actions>
        <slot name="bulk-edit-actions" :checked-issuables="bulkEditIssuables"></slot>
      </template>
      <template #sidebar-items>
        <slot name="sidebar-items" :checked-issuables="bulkEditIssuables"></slot>
      </template>
    </issuable-bulk-edit-sidebar>
    <slot name="list-body"></slot>
    <ul v-if="issuablesLoading" class="content-list">
      <li v-for="n in skeletonItemCount" :key="n" class="issue gl-px-5! gl-py-5!">
        <gl-skeleton-loader />
      </li>
    </ul>
    <template v-else>
      <component
        :is="issuablesWrapper"
        v-if="issuables.length > 0 && !isGridView"
        class="content-list issuable-list issues-list"
        :class="{ 'manual-ordering': isManualOrdering }"
        v-bind="$options.vueDraggableAttributes"
        @update="handleVueDraggableUpdate"
      >
        <issuable-item
          v-for="issuable in issuables"
          :key="issuableId(issuable)"
          :class="{ 'gl-cursor-grab': isManualOrdering }"
          data-testid="issuable-container"
          :data-qa-issuable-title="issuable.title"
          :has-scoped-labels-feature="hasScopedLabelsFeature"
          :issuable-symbol="issuableSymbol"
          :issuable="issuable"
          :label-filter-param="labelFilterParam"
          :show-checkbox="showBulkEditSidebar"
          :checked="issuableChecked(issuable)"
          :show-work-item-type-icon="showWorkItemTypeIcon"
          :prevent-redirect="preventRedirect"
          :is-active="isIssuableActive(issuable)"
          @checked-input="handleIssuableCheckedInput(issuable, $event)"
          @select-issuable="$emit('select-issuable', $event)"
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
          <template #pipeline-status>
            <slot name="pipeline-status" :issuable="issuable"></slot>
          </template>
        </issuable-item>
      </component>
      <div v-else-if="issuables.length > 0 && isGridView">
        <issuable-grid />
      </div>
      <slot v-else name="empty-state"></slot>
    </template>

    <div
      class="gl-display-flex gl-justify-content-space-between gl-md-justify-content-center! gl-mt-6 gl-relative"
    >
      <gl-keyset-pagination
        v-if="showPaginationControls && useKeysetPagination"
        :has-next-page="hasNextPage"
        :has-previous-page="hasPreviousPage"
        @next="$emit('next-page')"
        @prev="$emit('previous-page')"
      />
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

      <local-storage-sync
        v-if="showPageSizeChangeControls"
        :value="defaultPageSize"
        :storage-key="$options.PAGE_SIZE_STORAGE_KEY"
        @input="handlePageSizeChange"
      >
        <page-size-selector
          :value="defaultPageSize"
          class="gl-right-0 gl-relative md:gl-absolute"
          @input="handlePageSizeChange"
        />
      </local-storage-sync>
    </div>
  </div>
</template>
