<script>
import {
  GlButton,
  GlKeysetPagination,
  GlLoadingIcon,
  GlIcon,
  GlTooltipDirective,
  GlSkeletonLoader,
  GlModalDirective,
  GlAlert,
} from '@gitlab/ui';
import { isEmpty } from 'lodash-es';
import IssueCardStatistics from 'ee_else_ce/work_items/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/work_items/list/components/issue_card_time_info.vue';
import { convertToSearchQuery, getInitialPageParams } from 'ee_else_ce/work_items/list/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { STATUS_ALL, STATUS_OPEN } from '~/issues/constants';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import { RELATIVE_POSITION_ASC } from '~/work_items/list/constants';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import IssuableBulkEditSidebar from '~/vue_shared/issuable/list/components/issuable_bulk_edit_sidebar.vue';
import ResourceListsLoadingStateList from '~/vue_shared/components/resource_lists/loading_state_list.vue';
import IssuableItem from '~/vue_shared/issuable/list/components/issuable_item.vue';
import {
  DEFAULT_SKELETON_COUNT,
  PAGE_SIZE_STORAGE_KEY,
  DEFAULT_PAGE_SIZE,
} from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import WorkItemDrawer from '../components/work_item_drawer.vue';
import {
  DETAIL_VIEW_QUERY_PARAM_NAME,
  STATE_CLOSED,
  WORK_ITEM_TYPE_NAME_TICKET,
  WORK_ITEM_TYPE_NAME_EPIC,
  METADATA_KEYS,
  VIEW_CONTEXT,
} from '../constants';
import { findHierarchyWidget } from '../utils';

import HealthStatus from './components/health_status.vue';

const VueDraggable = () => import('~/lib/utils/vue3compat/draggable_compat.vue');

export default {
  name: 'ListView',
  VIEW_CONTEXT,
  importModalId: 'work-item-import-modal',
  components: {
    GlLoadingIcon,
    GlButton,
    GlKeysetPagination,
    IssuableBulkEditSidebar,
    IssuableItem,
    LocalStorageSync,
    PageSizeSelector,
    ResourceListsLoadingStateList,
    IssueCardStatistics,
    IssueCardTimeInfo,
    WorkItemBulkEditSidebar: () =>
      import('~/work_items/list/components/work_item_bulk_edit_sidebar.vue'),
    WorkItemDrawer,
    HealthStatus,
    GlIcon,
    GlSkeletonLoader,
    GlAlert,
    UserCalloutDismisser,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['isGroup', 'workItemType'],
  props: {
    rootPageFullPath: {
      type: String,
      required: true,
    },
    workItems: {
      type: Array,
      required: true,
    },
    hasWorkItems: {
      type: Boolean,
      required: true,
    },
    isInitialLoadComplete: {
      type: Boolean,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    detailLoading: {
      type: Boolean,
      required: true,
    },
    error: {
      type: String,
      required: false,
      default: undefined,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    initialLoadWasFiltered: {
      type: Boolean,
      required: true,
    },
    showBulkEditSidebar: {
      type: Boolean,
      required: true,
    },
    checkedIssuableIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    displaySettings: {
      type: Object,
      required: false,
      default: () => {},
    },
    pageSize: {
      type: Number,
      required: false,
      default: DEFAULT_PAGE_SIZE,
    },
    filterTokens: {
      type: Array,
      required: false,
      default: () => [],
    },
    apiFilterParams: {
      type: Object,
      required: false,
      default: () => {},
    },
    sortKey: {
      type: String,
      required: true,
    },
    isSortKeyInitialized: {
      type: Boolean,
      required: true,
    },
    state: {
      type: String,
      required: true,
    },
  },
  emits: [
    'refetch-data',
    'evict-cache',
    'toggle-bulk-edit-sidebar',
    'set-checked-issuable-ids',
    'set-page-params',
    'set-page-size',
    'reorder',
  ],
  data() {
    return {
      bulkEditInProgress: false,
      activeItem: null,
    };
  },
  computed: {
    issuablesWrapper() {
      return this.isManualOrdering ? VueDraggable : 'ul';
    },
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
    checkedIssuables() {
      return this.workItems.filter((issuable) => this.checkedIssuableIds.includes(issuable.id));
    },
    shouldShowList() {
      return (
        this.hasWorkItems === true ||
        this.error ||
        this.initialLoadWasFiltered ||
        this.workItems.length > 0 ||
        !this.isEpicsList
      );
    },
    isItemSelected() {
      return !isEmpty(this.activeItem);
    },
    workItemDrawerEnabled() {
      return this.displaySettings?.commonPreferences?.shouldOpenItemsInSidePanel ?? true;
    },
    isServiceDeskList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_TICKET;
    },
    isEpicsList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
    },
    hasSearch() {
      return Boolean(this.searchQuery);
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
    },
    searchQuery() {
      return convertToSearchQuery(this.filterTokens);
    },
    showPaginationControls() {
      return !this.isLoading && (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage);
    },
    showPageSizeSelector() {
      return this.workItems.length > 0;
    },
    activeWorkItemType() {
      const activeWorkItemTypeName =
        typeof this.activeItem?.workItemType === 'object'
          ? this.activeItem?.workItemType?.name
          : this.activeItem?.workItemType;
      return this.workItemType || activeWorkItemTypeName;
    },
    hiddenMetadataKeys() {
      return this.displaySettings?.namespacePreferences?.hiddenMetadataKeys || [];
    },
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION_ASC;
    },
    parentId() {
      return this.apiFilterParams?.hierarchyFilters?.parentIds?.[0] || null;
    },
    shouldLoad() {
      return !this.isInitialLoadComplete || (!this.isSortKeyInitialized && !this.error);
    },
  },
  watch: {
    workItems: {
      handler(value) {
        if (value.length > 0) {
          this.checkDrawerParams();
        }
      },
      immediate: true,
    },
    $route(newValue) {
      if (newValue.query[DETAIL_VIEW_QUERY_PARAM_NAME] && !this.detailLoading) {
        this.checkDrawerParams();
      } else {
        this.activeItem = null;
      }
    },
  },
  created() {
    window.addEventListener('popstate', this.checkDrawerParams);
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.checkDrawerParams);
  },
  methods: {
    handleReorder({ oldIndex, newIndex }) {
      this.$emit('reorder', { oldIndex, newIndex });
    },
    isIssuableChecked(issuable) {
      return this.checkedIssuableIds.includes(issuable.id);
    },
    isIssuableActive(issuable) {
      return Boolean(getIdFromGraphQLId(issuable.id) === getIdFromGraphQLId(this.activeItem?.id));
    },
    updateCheckedIssuableIds(issuable, toCheck) {
      const isIdChecked = this.checkedIssuableIds.includes(issuable.id);
      if (toCheck && !isIdChecked) {
        this.$emit('set-checked-issuable-ids', [...this.checkedIssuableIds, issuable.id]);
      }
      if (!toCheck && isIdChecked) {
        const indexToDelete = this.checkedIssuableIds.findIndex((id) => id === issuable.id);
        this.$emit('set-checked-issuable-ids', this.checkedIssuableIds.toSpliced(indexToDelete, 1));
      }
    },

    handleToggle(item) {
      if (item && this.activeItem?.iid === item.iid) {
        this.activeItem = null;
        const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);
        if (queryParam) {
          updateHistory({
            url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
          });
        }
      } else {
        this.activeItem = item;
      }
    },
    getStatus(issue) {
      return issue.state === STATE_CLOSED ? __('Closed') : undefined;
    },
    async handleBulkEditSuccess(event) {
      this.$emit('toggle-bulk-edit-sidebar', false);
      this.refetchItems(event);
      if (event?.toastMessage) {
        this.$toast.show(event.toastMessage);
      }
    },
    handleNextPage() {
      this.$emit('set-page-params', {
        afterCursor: this.pageInfo.endCursor,
        firstPageSize: this.pageSize,
      });
      scrollUp();
    },
    handlePageSizeChange(pageSize) {
      this.$emit('set-page-size', pageSize);
      this.$emit('set-page-params', {
        ...getInitialPageParams(pageSize),
      });
      scrollUp();
    },
    handlePreviousPage() {
      this.$emit('set-page-params', {
        beforeCursor: this.pageInfo.startCursor,
        lastPageSize: this.pageSize,
      });
      scrollUp();
    },
    deleteItem() {
      this.activeItem = null;
      this.refetchItems({ refetchCounts: true });
    },
    handleStatusChange(workItem) {
      if (this.state === STATUS_ALL) {
        return;
      }

      // Work item state can be either 'OPEN' or 'CLOSED', this.state can be 'opened' or 'closed'
      if (!this.state.includes(workItem.state.toLowerCase())) {
        this.refetchItems({ refetchCounts: true });
      }
    },
    async refetchItems({ refetchCounts = false } = {}) {
      if (refetchCounts) {
        this.$emit('refetch-data', 'counts');
      }
      this.$emit('evict-cache');
    },
    checkDrawerParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (!queryParam) {
        this.activeItem = null;
        return;
      }

      const params = JSON.parse(atob(queryParam));
      if (params.id) {
        const issue = this.workItems.find((i) => getIdFromGraphQLId(i.id) === params.id);
        if (issue) {
          this.activeItem = {
            ...issue,
            // we need fullPath here to prevent cache invalidation
            fullPath: params.full_path,
          };
        } else {
          updateHistory({
            url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
          });
        }
      }
    },
    isDirectChildOfWorkItem(workItem) {
      if (!workItem) {
        return false;
      }

      return findHierarchyWidget(workItem)?.parent?.id !== this.parentId;
    },
  },
  constants: {
    METADATA_KEYS,
    PAGE_SIZE_STORAGE_KEY,
  },
};
</script>

<template>
  <gl-loading-icon v-if="shouldLoad" class="gl-mt-5" size="lg" />

  <div
    v-else-if="shouldShowList"
    :class="{ 'work-item-list-container': !isServiceDeskList }"
    class="issuable-list-container"
  >
    <work-item-drawer
      v-if="workItemDrawerEnabled"
      :active-item="activeItem"
      :open="isItemSelected"
      :issuable-type="activeWorkItemType"
      :view-context="$options.VIEW_CONTEXT.drawerList"
      click-outside-exclude-selector=".issuable-list"
      @close="activeItem = null"
      @add-child="refetchItems"
      @work-item-deleted="deleteItem"
      @work-item-updated="handleStatusChange"
    />
    <issuable-bulk-edit-sidebar :expanded="showBulkEditSidebar">
      <template #bulk-edit-actions>
        <gl-button
          :disabled="!checkedIssuables.length || bulkEditInProgress"
          form="work-item-list-bulk-edit"
          :loading="bulkEditInProgress"
          type="submit"
          variant="confirm"
        >
          {{ __('Update selected') }}
        </gl-button>
        <gl-button class="gl-float-right" @click="$emit('toggle-bulk-edit-sidebar', false)">
          {{ __('Cancel') }}
        </gl-button>
      </template>
      <template #sidebar-items>
        <div class="work-item-bulk-edit-sidebar-wrapper gl-overflow-y-auto">
          <work-item-bulk-edit-sidebar
            v-if="showBulkEditSidebar"
            :checked-items="checkedIssuables"
            :full-path="rootPageFullPath"
            :is-epics-list="isEpicsList"
            :is-group="isGroup"
            @finish="bulkEditInProgress = false"
            @start="bulkEditInProgress = true"
            @success="handleBulkEditSuccess"
          />
        </div>
      </template>
    </issuable-bulk-edit-sidebar>

    <resource-lists-loading-state-list
      v-if="isLoading"
      :left-lines-count="3"
      :list-length="skeletonItemCount"
    />
    <template v-else>
      <component
        :is="issuablesWrapper"
        v-if="workItems.length > 0"
        :value="workItems"
        item-key="id"
        class="content-list issuable-list issues-list"
        :class="{ 'manual-ordering': isManualOrdering }"
        v-bind="$options.vueDraggableAttributes"
        data-testid="work-item-list-wrapper"
        @update="handleReorder"
      >
        <issuable-item
          v-for="workItem in workItems"
          :key="workItem.id"
          :class="{ 'gl-cursor-grab': isManualOrdering }"
          data-testid="issuable-container"
          :data-qa-issuable-title="workItem.title"
          :issuable="workItem"
          label-filter-param="label_name"
          issuable-symbol="#"
          :full-path="rootPageFullPath"
          :show-checkbox="showBulkEditSidebar"
          :checked="isIssuableChecked(workItem)"
          show-work-item-type-icon
          :prevent-redirect="workItemDrawerEnabled"
          :is-active="isIssuableActive(workItem)"
          :detail-loading="detailLoading"
          :hidden-metadata-keys="hiddenMetadataKeys"
          @checked-input="updateCheckedIssuableIds(workItem, $event)"
          @select-issuable="handleToggle"
        >
          <template #timeframe>
            <issue-card-time-info
              :issue="workItem"
              :is-work-item-list="true"
              :hidden-metadata-keys="hiddenMetadataKeys"
              :detail-loading="detailLoading"
            />
          </template>

          <template #status>
            {{ getStatus(workItem) }}
          </template>

          <template #statistics>
            <issue-card-statistics :issue="workItem" />
          </template>

          <template #health-status>
            <health-status
              v-if="!hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.HEALTH)"
              :issue="workItem"
            />
          </template>

          <template #custom-status>
            <slot
              v-if="!hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.STATUS)"
              name="custom-status"
              :issuable="workItem"
            ></slot>
          </template>

          <template v-if="parentId" #title-icons>
            <span
              v-if="!detailLoading && isDirectChildOfWorkItem(workItem)"
              v-gl-tooltip
              data-testid="sub-child-work-item-indicator"
              :title="__('This item belongs to a descendant of the filtered parent.')"
              class="gl-ml-1 gl-inline-block"
            >
              <gl-icon name="file-tree" variant="subtle" />
            </span>
            <gl-skeleton-loader
              v-if="detailLoading"
              class="gl-ml-1 gl-inline-block"
              :width="20"
              :lines="1"
              equal-width-lines
            />
          </template>
        </issuable-item>
      </component>
      <template v-if="!error && workItems.length === 0">
        <slot
          name="list-empty-state"
          :has-search="hasSearch"
          :is-open-tab="isOpenTab"
          :with-tabs="false"
        >
        </slot>
      </template>
    </template>

    <div
      data-testid="list-footer"
      class="gl-relative gl-mt-6 gl-flex gl-justify-between @md/panel:!gl-justify-center"
    >
      <gl-keyset-pagination
        v-if="showPaginationControls"
        :has-next-page="pageInfo.hasNextPage"
        :has-previous-page="pageInfo.hasPreviousPage"
        @next="handleNextPage"
        @prev="handlePreviousPage"
      />

      <local-storage-sync
        v-if="showPageSizeSelector"
        :value="pageSize"
        :storage-key="$options.constants.PAGE_SIZE_STORAGE_KEY"
        @input="handlePageSizeChange"
      >
        <page-size-selector
          :value="pageSize"
          class="gl-relative gl-right-0 @md/panel:gl-absolute"
          @input="handlePageSizeChange"
        />
      </local-storage-sync>
    </div>
  </div>

  <div v-else>
    <slot name="page-empty-state"></slot>
  </div>
</template>
