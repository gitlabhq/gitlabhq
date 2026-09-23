<script>
import { defineAsyncComponent } from 'vue';
import { GlButton, GlLoadingIcon, GlSkeletonLoader, GlToastMixin } from '@gitlab/ui';
import { isEmpty, omit } from 'lodash-es';
import { convertToSearchQuery } from 'ee_else_ce/work_items/list/utils';
import IssuableBulkEditSidebar from '~/vue_shared/issuable/list/components/issuable_bulk_edit_sidebar.vue';
import { evictNamespaceWorkItems } from '~/work_items/list/graphql/cache_updates';
import getWorkItemsQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import { STATUS_OPEN } from '~/issues/constants';
import { CREATED_DESC } from '~/work_items/list/constants';
import { formatNumber, s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { DEFAULT_PAGE_SIZE, DEFAULT_SKELETON_COUNT } from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import { DETAIL_VIEW_QUERY_PARAM_NAME, WORK_ITEM_TYPE_NAME_EPIC } from '../constants';
import {
  combineWorkItemLists,
  findDetailPanelWorkItem,
  getSortedWorkItems,
  getWorkItemsConnection,
} from '../utils';
import { CURSOR_VARIABLES, TABLE_COLUMNS } from './constants';
import WorkItemTableRow from './components/work_item_table_row.vue';

export default {
  name: 'TableView',
  components: {
    GlButton,
    GlLoadingIcon,
    GlSkeletonLoader,
    IssuableBulkEditSidebar,
    WorkItemTableRow,
    WorkItemBulkEditSidebar: defineAsyncComponent(
      () => import('~/work_items/list/components/work_item_bulk_edit_sidebar.vue'),
    ),
  },
  mixins: [glFeatureFlagMixin(), GlToastMixin],
  inject: [
    'hasIssuableHealthStatusFeature',
    'hasIssueWeightsFeature',
    'hasIterationsFeature',
    'hasStatusFeature',
    'isGroup',
    'workItemType',
  ],
  // The list and table views share a prop contract, and the table doesn't use every list-only
  // prop, so keep the rest from landing on the root element.
  inheritAttrs: false,
  apollo: {
    workItemsFull() {
      const query = this.createWorkItemQuery(getWorkItemsQuery);
      if (this.useRestApi) {
        return { ...query, skip: true };
      }
      return query;
    },
    workItemsSlim() {
      const query = this.useRestApi ? getWorkItemsRestQuery : getWorkItemsSlimQuery;
      // The full query is skipped in REST mode, so only the slim one is guaranteed to run —
      // that's why it's the one tracking pagination state.
      return this.createWorkItemQuery(query, { tracksPageInfo: true });
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
    displaySettings: {
      type: Object,
      required: false,
      default: () => ({}),
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
    isSortKeyInitialized: {
      type: Boolean,
      required: true,
    },
    state: {
      type: String,
      required: true,
    },
    workItemsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    activeItem: {
      type: Object,
      required: false,
      default: null,
    },
    showBulkEditSidebar: {
      type: Boolean,
      required: false,
      default: false,
    },
    checkedIssuableIds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: [
    'namespace-data-loaded',
    'refetch-data',
    'set-active-item',
    'set-checked-issuable-ids',
    'set-error',
    'toggle-bulk-edit-sidebar',
    'work-items-changed',
  ],
  data() {
    return {
      workItemsFull: [],
      workItemsSlim: [],
      isInitialLoadComplete: false,
      bulkEditInProgress: false,
      namespaceId: null,
      pageInfo: {},
      afterCursor: null,
      previousPagesSlim: [],
      previousPagesFull: [],
      pendingPageQueries: 0,
      loadMoreError: false,
    };
  },
  computed: {
    useRestApi() {
      return Boolean(this.glFeatures.workItemRestApiFrontendUsers);
    },
    firstPageVariables() {
      return { ...omit(this.queryVariables, CURSOR_VARIABLES), firstPageSize: this.pageSize };
    },
    pageVariables() {
      return this.afterCursor
        ? { ...this.firstPageVariables, afterCursor: this.afterCursor }
        : this.firstPageVariables;
    },
    // Earlier pages are kept in component state rather than the Apollo cache. The slim and full
    // queries write the same cache entry with different fields, so merging there would let one
    // query overwrite the other's data with gaps.
    workItems() {
      const combined = combineWorkItemLists(
        [...this.previousPagesSlim, ...this.workItemsSlim],
        [...this.previousPagesFull, ...this.workItemsFull],
        !this.useRestApi && Boolean(this.glFeatures.workItemFeaturesField),
      );
      return getSortedWorkItems(combined, this.queryVariables.sort || CREATED_DESC);
    },
    columns() {
      return TABLE_COLUMNS.filter(
        (column) => this.isColumnLicensed(column) && !this.isColumnHidden(column),
      );
    },
    hiddenMetadataKeys() {
      return this.displaySettings?.namespacePreferences?.hiddenMetadataKeys || [];
    },
    workItemDetailPanelEnabled() {
      return this.displaySettings?.commonPreferences?.shouldOpenItemsInSidePanel ?? true;
    },
    checkedIssuables() {
      return this.workItems.filter((workItem) => this.checkedIssuableIds.includes(workItem.id));
    },
    // Stays true until both queries return, since a work item isn't complete until its slim
    // and full halves are combined.
    fetchNextPageInProgress() {
      return this.pendingPageQueries > 0;
    },
    // Apollo's loading flag is also true while fetching an extra page with "Load more", but
    // that shouldn't trigger the full-table skeleton, only an actual (re)load should.
    isLoading() {
      return this.$apollo.queries.workItemsSlim.loading && !this.fetchNextPageInProgress;
    },
    hasNextPage() {
      return Boolean(this.pageInfo.hasNextPage && this.pageInfo.endCursor);
    },
    // The button doubles as the retry for a page that failed, so it stays put after a failure
    // even when the page that did load reported nothing more to fetch.
    showLoadMoreButton() {
      return this.hasNextPage || this.loadMoreError || this.fetchNextPageInProgress;
    },
    // The full query fills in metadata for the page on screen, and archiving that page before it
    // arrives would lose those fields for good, so the next page has to wait for it.
    detailLoading() {
      return !this.useRestApi && this.$apollo.queries.workItemsFull.loading;
    },
    showPaginationFooter() {
      return !this.isLoading && this.workItems.length > 0;
    },
    paginationText() {
      return sprintf(s__('WorkItem|Showing 1-%{loaded} of %{total}'), {
        loaded: formatNumber(this.workItems.length),
        total: formatNumber(this.workItemsCount),
      });
    },
    shouldLoad() {
      return !this.isInitialLoadComplete || (!this.isSortKeyInitialized && !this.error);
    },
    isEpicsList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
    },
    showPageEmptyState() {
      return (
        this.isEpicsList &&
        !this.hasWorkItems &&
        !this.error &&
        !this.initialLoadWasFiltered &&
        this.workItems.length === 0
      );
    },
    // The table keeps its header on screen while a page loads, so rows are swapped for
    // skeletons rather than hiding the whole table.
    hasRows() {
      return this.isLoading || this.workItems.length > 0;
    },
    skeletonRowCount() {
      return this.workItemsCount > 0
        ? Math.min(this.pageSize, this.workItemsCount)
        : DEFAULT_SKELETON_COUNT;
    },
    // How many skeleton rows to show: a full page while (re)loading, or just the size of the
    // next page while "Load more" is in flight.
    pendingRowCount() {
      if (this.isLoading) {
        return this.skeletonRowCount;
      }
      if (!this.fetchNextPageInProgress) {
        return 0;
      }
      const remaining = this.workItemsCount - this.workItems.length;
      return remaining > 0 ? Math.min(this.pageSize, remaining) : this.pageSize;
    },
    showListEmptyState() {
      return !this.isLoading && !this.error && this.workItems.length === 0;
    },
    hasSearch() {
      return Boolean(convertToSearchQuery(this.filterTokens));
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
    },
  },
  watch: {
    // New filters, sort or page size mean a different result set, so paging starts over.
    firstPageVariables() {
      this.afterCursor = null;
      this.previousPagesSlim = [];
      this.previousPagesFull = [];
      this.pendingPageQueries = 0;
      this.loadMoreError = false;
    },
    workItems: {
      handler(value) {
        if (!this.shouldLoad && this.workItemsSlim.length > 0) {
          this.checkDetailPanelParams();
        }
        this.$emit('work-items-changed', {
          count: value.length,
          ids: value.map((workItem) => workItem.id),
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
    createWorkItemQuery(query, { tracksPageInfo = false } = {}) {
      return {
        query,
        context: {
          featureCategory: 'portfolio_management',
        },
        variables() {
          return this.pageVariables;
        },
        update(data) {
          return getWorkItemsConnection(data, this.useRestApi)?.nodes ?? [];
        },
        skip() {
          return isEmpty(this.queryVariables) || this.skipQuery;
        },
        result({ data }) {
          this.handleTableDataResults(data, tracksPageInfo);
        },
        error(error) {
          Sentry.captureException(error);

          // A failed "Load more" leaves already-loaded rows on screen, so this reports the
          // specific failure instead of the generic error. `loadMoreError` stops the second
          // query (slim or full) from overwriting that message when both fail for one page.
          if (this.fetchNextPageInProgress || this.loadMoreError) {
            this.pendingPageQueries = 0;
            this.loadMoreError = true;
            this.$emit(
              'set-error',
              s__('WorkItem|An error occurred while fetching more work items.'),
            );
            return;
          }
          this.isInitialLoadComplete = true;
          this.$emit(
            'set-error',
            s__('WorkItem|Something went wrong when fetching work items. Please try again.'),
          );
        },
      };
    },
    handleTableDataResults(data, tracksPageInfo) {
      const connection = getWorkItemsConnection(data, this.useRestApi);
      // Don't overwrite pageInfo with an empty result on failure — keeping the last real cursor
      // lets the failed page be retried instead of silently skipped.
      if (tracksPageInfo && connection) {
        this.pageInfo = connection.pageInfo ?? {};
      }
      if (this.pendingPageQueries > 0) {
        this.pendingPageQueries -= 1;
      }
      if (data?.namespace) {
        this.namespaceId = data.namespace.id;
        this.$emit('namespace-data-loaded', { namespaceName: data.namespace.name, data });
      }
      this.isInitialLoadComplete = true;
    },
    checkDetailPanelParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (!queryParam) {
        this.$emit('set-active-item', null);
        return;
      }

      const { item, notFound } = findDetailPanelWorkItem(
        queryParam,
        this.workItems,
        this.activeItem,
      );
      if (item) {
        this.$emit('set-active-item', item);
      } else if (notFound) {
        updateHistory({ url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]) });
      }
    },
    handleSetActiveItem(item) {
      this.$emit('set-active-item', item);
      if (!item) {
        updateHistory({ url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]) });
      }
    },
    isIssuableChecked(workItem) {
      return this.checkedIssuableIds.includes(workItem.id);
    },
    updateCheckedIssuableIds(workItem, toCheck) {
      const isIdChecked = this.isIssuableChecked(workItem);
      if (toCheck && !isIdChecked) {
        this.$emit('set-checked-issuable-ids', [...this.checkedIssuableIds, workItem.id]);
      }
      if (!toCheck && isIdChecked) {
        this.$emit(
          'set-checked-issuable-ids',
          this.checkedIssuableIds.filter((id) => id !== workItem.id),
        );
      }
    },
    handleBulkEditSuccess(event) {
      this.$emit('toggle-bulk-edit-sidebar', false);
      this.refetchItems(event);
      if (event?.toastMessage) {
        this.$toast.show(event.toastMessage);
      }
    },
    refetchItems({ refetchCounts = false } = {}) {
      if (refetchCounts) {
        this.$emit('refetch-data', 'counts');
      }
      evictNamespaceWorkItems(this.$apollo.provider.defaultClient.cache, this.namespaceId, {
        useRestApi: this.useRestApi,
      });
    },
    fetchNextPage() {
      if (this.fetchNextPageInProgress || this.detailLoading) {
        return;
      }
      if (!this.hasNextPage && !this.loadMoreError) {
        return;
      }

      // A failed attempt can leave the page half fetched, with the slim query's rows in hand
      // but not the full query's (or the other way round), so this click fetches the same page
      // again rather than moving on and leaving a gap in the table.
      const isRetry = this.loadMoreError;
      if (isRetry) {
        this.$emit('set-error', undefined);
        this.loadMoreError = false;
      }
      this.pendingPageQueries = this.pageQueries().length;

      if (isRetry) {
        this.refetchPage();
        return;
      }

      this.previousPagesSlim = [...this.previousPagesSlim, ...this.workItemsSlim];
      this.previousPagesFull = [...this.previousPagesFull, ...this.workItemsFull];
      this.workItemsSlim = [];
      this.workItemsFull = [];
      this.afterCursor = this.pageInfo.endCursor;
    },
    // The queries a page is fetched with: the REST query stands in for both GraphQL ones, so
    // a page is one request in that mode and two in the other.
    pageQueries() {
      const { workItemsSlim, workItemsFull } = this.$apollo.queries;
      return this.useRestApi ? [workItemsSlim] : [workItemsSlim, workItemsFull];
    },
    refetchPage() {
      // Swallow the rejection here, the error() hook on each query already reports it.
      this.pageQueries().forEach((query) => query.refetch().catch(() => {}));
    },
    isColumnLicensed(column) {
      return !column.licensedFeature || Boolean(this[column.licensedFeature]);
    },
    isColumnHidden(column) {
      return Boolean(column.metadataKey) && this.hiddenMetadataKeys.includes(column.metadataKey);
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="shouldLoad" class="gl-mt-5" size="lg" />

  <div v-else-if="showPageEmptyState">
    <slot name="page-empty-state"></slot>
  </div>

  <div v-else class="issuable-list-container" data-testid="table-view">
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

    <div v-if="hasRows" class="gl-border gl-overflow-x-auto gl-rounded-lg">
      <table
        class="gl-min-w-full gl-table-fixed gl-border-collapse gl-text-sm"
        data-testid="work-item-table"
      >
        <caption class="gl-sr-only">
          {{
            __('Work items')
          }}
        </caption>
        <colgroup>
          <col v-if="showBulkEditSidebar" class="gl-w-10" />
          <col v-for="column in columns" :key="column.key" :class="column.widthClass" />
        </colgroup>
        <thead>
          <tr class="gl-border-b gl-bg-subtle">
            <!-- Select all lives in the filtered search bar, so this only names the column. -->
            <th v-if="showBulkEditSidebar" scope="col" class="gl-border-r gl-px-4 gl-py-3">
              <span class="gl-sr-only">{{ s__('WorkItem|Select work item') }}</span>
            </th>
            <th
              v-for="column in columns"
              :key="column.key"
              scope="col"
              class="gl-border-r gl-truncate gl-px-4 gl-py-3 gl-text-left gl-font-normal gl-text-strong last:gl-border-r-0"
            >
              {{ column.label }}
            </th>
          </tr>
        </thead>
        <tbody :aria-busy="isLoading || fetchNextPageInProgress">
          <template v-if="!isLoading">
            <work-item-table-row
              v-for="workItem in workItems"
              :key="workItem.id"
              :item="workItem"
              :columns="columns"
              :root-page-full-path="rootPageFullPath"
              :active-item="activeItem"
              :detail-panel-enabled="workItemDetailPanelEnabled"
              :show-checkbox="showBulkEditSidebar"
              :checked="isIssuableChecked(workItem)"
              @set-active-item="handleSetActiveItem"
              @checked-input="updateCheckedIssuableIds(workItem, $event)"
            />
          </template>
          <tr v-for="row in pendingRowCount" :key="`skeleton-${row}`" class="gl-border-b">
            <td v-if="showBulkEditSidebar" class="gl-border-r gl-px-4 gl-py-3"></td>
            <td
              v-for="column in columns"
              :key="column.key"
              class="gl-border-r gl-px-4 gl-py-3 last:gl-border-r-0"
            >
              <gl-skeleton-loader :width="60" :lines="1" equal-width-lines />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showPaginationFooter" class="gl-mt-4 gl-flex gl-items-center gl-gap-3">
      <gl-button
        v-if="showLoadMoreButton"
        size="small"
        :loading="fetchNextPageInProgress"
        :disabled="detailLoading"
        data-testid="load-more-button"
        @click="fetchNextPage"
      >
        {{ s__('WorkItem|Load more') }}
      </gl-button>
      <span v-if="workItemsCount > 0" class="gl-text-sm gl-text-subtle" data-testid="page-summary">
        {{ paginationText }}
      </span>
    </div>

    <slot
      v-if="showListEmptyState"
      name="list-empty-state"
      :has-search="hasSearch"
      :is-open-tab="isOpenTab"
      :with-tabs="false"
    ></slot>
  </div>
</template>
