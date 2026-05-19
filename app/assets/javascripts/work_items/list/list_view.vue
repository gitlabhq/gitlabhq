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
import produce from 'immer';
import { isEmpty } from 'lodash-es';
import IssueCardStatistics from 'ee_else_ce/work_items/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/work_items/list/components/issue_card_time_info.vue';
import { convertToSearchQuery, getInitialPageParams } from 'ee_else_ce/work_items/list/utils';
import getWorkItemsQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import getWorkItemsRestQuery from '~/work_items/list/graphql/get_work_items_rest.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_NAMESPACE } from '~/graphql_shared/constants';
import { STATUS_OPEN } from '~/issues/constants';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import { RELATIVE_POSITION_ASC, CREATED_DESC } from '~/work_items/list/constants';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { __, s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
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
import workItemsReorderMutation from '~/work_items/graphql/work_items_reorder.mutation.graphql';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import {
  STATE_CLOSED,
  WORK_ITEM_TYPE_NAME_TICKET,
  WORK_ITEM_TYPE_NAME_EPIC,
  METADATA_KEYS,
  DETAIL_VIEW_QUERY_PARAM_NAME,
} from '../constants';
import { combineWorkItemLists, findHierarchyWidget, getSortedWorkItems } from '../utils';

import HealthStatus from './components/health_status.vue';

const VueDraggable = () => import('~/lib/utils/vue3compat/draggable_compat.vue');

export default {
  name: 'ListView',
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
  apollo: {
    workItemsFull() {
      return this.createWorkItemQuery(getWorkItemsQuery);
    },
    workItemsSlim() {
      const query =
        this.glFeatures.workItemRestApiFrontendUsers && this.glFeatures.workItemRestApi
          ? getWorkItemsRestQuery
          : getWorkItemsSlimQuery;
      return this.createWorkItemQuery(query);
    },
  },
  props: {
    rootPageFullPath: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
    skipQuery: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasWorkItems: {
      type: Boolean,
      required: true,
    },
    error: {
      type: String,
      required: false,
      default: undefined,
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
    activeItem: {
      type: Object,
      required: false,
      default: null,
    },
    workItemsCount: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  emits: [
    'refetch-data',
    'toggle-bulk-edit-sidebar',
    'set-checked-issuable-ids',
    'set-page-params',
    'set-page-size',
    'select-item',
    'set-active-item',
    'work-items-changed',
    'namespace-data-loaded',
    'set-error',
  ],
  data() {
    return {
      bulkEditInProgress: false,
      workItemsFull: [],
      workItemsSlim: [],
      namespaceId: null,
      pageInfo: {},
      isInitialLoadComplete: false,
    };
  },
  computed: {
    issuablesWrapper() {
      return this.isManualOrdering ? VueDraggable : 'ul';
    },
    workItems() {
      const useRestApi =
        this.glFeatures.workItemRestApiFrontendUsers && this.glFeatures.workItemRestApi;
      const combined = combineWorkItemLists(
        this.workItemsSlim,
        this.workItemsFull,
        !useRestApi && Boolean(this.glFeatures.workItemFeaturesField),
      );
      const sortKey = this.queryVariables.sort || CREATED_DESC;
      return getSortedWorkItems(combined, sortKey);
    },
    isLoading() {
      return this.$apollo.queries.workItemsSlim.loading;
    },
    detailLoading() {
      return this.$apollo.queries.workItemsFull.loading;
    },
    skeletonItemCount() {
      const { workItemsCount, pageSize } = this;
      const totalPages = Math.ceil(workItemsCount / pageSize);
      return totalPages ? pageSize : DEFAULT_SKELETON_COUNT;
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
    workItemDetailPanelEnabled() {
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
        if (!this.shouldLoad) {
          this.checkDetailPanelParams();
        }
        this.$emit('work-items-changed', {
          count: value.length,
          ids: value.map((i) => i.id),
        });
      },
      immediate: true,
    },
    $route(newValue) {
      if (newValue.query[DETAIL_VIEW_QUERY_PARAM_NAME]) {
        this.checkDetailPanelParams();
      } else {
        this.$emit('set-active-item', null);
      }
    },
  },
  methods: {
    createWorkItemQuery(query) {
      return {
        query,
        context: {
          featureCategory: 'portfolio_management',
        },
        variables() {
          return this.queryVariables;
        },
        update(data) {
          return data?.namespace?.workItems.nodes ?? [];
        },
        skip() {
          return isEmpty(this.queryVariables) || this.skipQuery;
        },
        result({ data }) {
          this.handleListDataResults(data);
        },
        error(error) {
          this.$emit(
            'set-error',
            s__('WorkItem|Something went wrong when fetching work items. Please try again.'),
          );
          Sentry.captureException(error);
        },
      };
    },
    handleListDataResults(data) {
      this.pageInfo = data?.namespace?.workItems.pageInfo ?? {};
      this.namespaceId = data?.namespace?.id;

      if (data?.namespace) {
        this.$emit('namespace-data-loaded', { namespaceName: data.namespace.name, data });
      }
      this.isInitialLoadComplete = true;
    },
    handleEvictCache() {
      const { cache } = this.$apollo.provider.defaultClient;
      cache.evict({
        id: cache.identify({ __typename: TYPENAME_NAMESPACE, id: this.namespaceId }),
        fieldName: 'workItems',
      });
      cache.gc();
    },
    checkDetailPanelParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (!queryParam) {
        this.$emit('set-active-item', null);
        return;
      }

      const params = JSON.parse(atob(queryParam));
      if (params.id) {
        const issue = this.workItems.find((i) => getIdFromGraphQLId(i.id) === params.id);
        if (issue) {
          this.$emit('set-active-item', {
            ...issue,
            fullPath: params.full_path,
          });
        } else {
          updateHistory({
            url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
          });
        }
      }
    },
    handleReorder({ newIndex, oldIndex }) {
      if (newIndex === oldIndex) return Promise.resolve();

      const workItemToMove = this.workItems[oldIndex];
      const remainingItems = this.workItems.filter((_, index) => index !== oldIndex);

      let moveBeforeId = null;
      let moveAfterId = null;

      if (newIndex === 0) {
        moveBeforeId = null;
        moveAfterId = remainingItems[0]?.id || null;
      } else if (newIndex >= remainingItems.length) {
        moveAfterId = null;
        moveBeforeId = remainingItems[remainingItems.length - 1]?.id || null;
      } else {
        moveAfterId = remainingItems[newIndex - 1]?.id || null;
        moveBeforeId = remainingItems[newIndex]?.id || null;
      }

      const input = { id: workItemToMove.id };
      if (moveBeforeId) input.moveBeforeId = moveBeforeId;
      if (moveAfterId) input.moveAfterId = moveAfterId;

      return this.$apollo
        .mutate({
          mutation: workItemsReorderMutation,
          variables: { input },
          update: (cache) => {
            this.updateWorkItemsCache(cache, oldIndex, newIndex);
          },
        })
        .then(({ data }) => {
          if (data?.workItemsReorder?.errors?.length > 0) {
            throw new Error(data.workItemsReorder.errors.join(', '));
          }
          return data;
        })
        .catch((error) => {
          this.$emit('set-error', s__('WorkItem|An error occurred while reordering work items.'));
          Sentry.captureException(error);
          throw error;
        });
    },
    updateWorkItemsCache(cache, oldIndex, newIndex) {
      cache.updateQuery(
        {
          query: getWorkItemsQuery,
          variables: this.queryVariables,
        },
        (existingData) => {
          if (!existingData?.namespace?.workItems?.nodes) {
            return existingData;
          }

          const workItems = [...existingData.namespace.workItems.nodes];

          if (oldIndex >= 0 && oldIndex < workItems.length) {
            const [movedItem] = workItems.splice(oldIndex, 1);
            if (movedItem) {
              workItems.splice(newIndex, 0, movedItem);
            }
          }

          return produce(existingData, (draftData) => {
            draftData.namespace.workItems.nodes = workItems;
          });
        },
      );
    },
    isIssuableChecked(issuable) {
      return this.checkedIssuableIds.includes(issuable.id);
    },
    isIssuableActive(issuable) {
      return Boolean(getIdFromGraphQLId(issuable.id) === getIdFromGraphQLId(this.activeItem?.id));
    },
    handleSelectIssuable(item) {
      this.$emit('select-item', item);
      if (!item) {
        updateHistory({ url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]) });
      }
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
    async refetchItems({ refetchCounts = false } = {}) {
      if (refetchCounts) {
        this.$emit('refetch-data', 'counts');
      }
      this.handleEvictCache();
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
          :prevent-redirect="workItemDetailPanelEnabled"
          :is-active="isIssuableActive(workItem)"
          :detail-loading="detailLoading"
          :hidden-metadata-keys="hiddenMetadataKeys"
          @checked-input="updateCheckedIssuableIds(workItem, $event)"
          @select-issuable="handleSelectIssuable"
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
