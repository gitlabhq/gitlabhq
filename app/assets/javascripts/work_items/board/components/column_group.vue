<script>
import { uniqueId } from 'lodash-es';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DraggableCompat from '~/lib/utils/vue3compat/draggable_compat.vue';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';
import WorkItemChildrenLoadMore from '~/work_items/components/shared/work_item_children_load_more.vue';
import { DEFAULT_PAGE_SIZE_BOARD_COLUMN_SUBSEQUENT } from '~/work_items/constants';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';

import { boardColumnQuery, boardColumnQueryVariables, boardColumnCountVariables } from '../utils';
import { BOARD_DND_GROUP, BOARD_CARD_CLASS } from '../constants';
import ColumnHeader from './column_header.vue';
import WorkItemCard from './work_item_card.vue';
import WorkItemCardSkeleton from './work_item_card_skeleton.vue';

export default {
  name: 'ColumnGroup',
  // Number of ghost cards shown while loading the initial page or paginating.
  skeletonCount: 3,
  // `draggable` is scoped to the card class so the load-more row stays fixed.
  sortableOptions: {
    ...defaultSortableOptions,
    draggable: `.${BOARD_CARD_CLASS}`,
    delay: DRAG_DELAY,
    delayOnTouchOnly: true,
  },
  i18n: {
    emptyText: s__('WorkItemBoard|No items'),
    fetchError: s__('WorkItemBoard|An error occurred while fetching work items for this column.'),
    loadMoreError: s__('WorkItemBoard|An error occurred while fetching more work items.'),
  },
  components: {
    ColumnHeader,
    DraggableCompat,
    WorkItemCard,
    WorkItemCardSkeleton,
    WorkItemChildrenLoadMore,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    value: {
      type: Object,
      required: true,
    },
    strategy: {
      type: Object,
      required: true,
    },
    rootPageFullPath: {
      type: String,
      required: true,
    },
    baseQueryVariables: {
      type: Object,
      required: true,
    },
    dragDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    dropDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
    hiddenMetadataKeys: {
      type: Array,
      required: false,
      default: () => [],
    },
    activeItem: {
      type: Object,
      required: false,
      default: null,
    },
    detailPanelEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  emits: ['card-move', 'set-active-item', 'toggle-collapse', 'drag-start'],
  data() {
    return {
      workItemsConnection: { nodes: [], pageInfo: {} },
      totalCount: 0,
      error: null,
      loadMoreError: false,
      fetchNextPageInProgress: false,
      columnBodyId: uniqueId('board-column-body-'),
    };
  },
  computed: {
    isLoading() {
      // Initial load only; once items exist the load-more component owns the
      // in-progress indicator, so the column spinner never replaces the list.
      return this.$apollo.queries.workItemsConnection.loading && this.workItems.length === 0;
    },
    workItems() {
      return this.workItemsConnection?.nodes ?? [];
    },
    pageInfo() {
      return this.workItemsConnection?.pageInfo ?? {};
    },
    hasNextPage() {
      return Boolean(this.pageInfo.hasNextPage);
    },
    showEmptyState() {
      return !this.isLoading && !this.fetchNextPageInProgress && this.workItems.length === 0;
    },
    queryVariables() {
      return boardColumnQueryVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.baseQueryVariables,
        columnFilter: this.strategy.columnFilter(this.value),
      });
    },
    decoration() {
      return this.strategy.headerDecoration(this.value);
    },
    groupConfig() {
      // Shared group so cards drag between columns; `put: false` makes THIS column
      // reject incoming drops (a status the dragged type can't take) while others accept.
      return { name: BOARD_DND_GROUP, put: !this.dropDisabled };
    },
    countQueryVariables() {
      return boardColumnCountVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.baseQueryVariables,
        columnFilter: this.strategy.columnFilter(this.value),
      });
    },
  },
  apollo: {
    workItemsConnection() {
      const query = boardColumnQuery(this.glFeatures);
      return {
        query,
        skip() {
          return this.collapsed;
        },
        update(data) {
          return data?.namespace?.workItems ?? { nodes: [], pageInfo: {} };
        },
        result(result) {
          if (!result.error) {
            this.error = null;
          }
        },
        variables() {
          return this.queryVariables;
        },
        error(error) {
          // Pagination failures are surfaced inline by fetchNextPage so that
          // already-loaded items stay visible; only the initial load replaces the column.
          if (this.fetchNextPageInProgress) {
            return;
          }
          this.error = this.$options.i18n.fetchError;
          Sentry.captureException(error);
        },
      };
    },
    totalCount() {
      return {
        query: getWorkItemsCountOnlyQuery,
        variables() {
          return this.countQueryVariables;
        },
        update(data) {
          return data?.namespace?.workItems?.count ?? 0;
        },
        error(error) {
          Sentry.captureException(error);
        },
      };
    },
  },
  methods: {
    onDragStart(evt) {
      const workItemId = evt.item?.dataset?.workItemId;
      this.$emit(
        'drag-start',
        this.workItems.find((workItem) => workItem.id === workItemId),
      );
    },
    fetchNextPage() {
      if (!this.hasNextPage || this.fetchNextPageInProgress) {
        return;
      }

      this.fetchNextPageInProgress = true;
      this.loadMoreError = false;

      this.$apollo.queries.workItemsConnection
        .fetchMore({
          variables: {
            ...this.queryVariables,
            firstPageSize: DEFAULT_PAGE_SIZE_BOARD_COLUMN_SUBSEQUENT,
            afterCursor: this.pageInfo.endCursor,
          },
          updateQuery(previousResult, { fetchMoreResult }) {
            const previousConnection = previousResult?.namespace?.workItems;
            const newConnection = fetchMoreResult?.namespace?.workItems;

            if (!newConnection) {
              return previousResult;
            }

            return {
              ...fetchMoreResult,
              namespace: {
                ...fetchMoreResult.namespace,
                workItems: {
                  ...newConnection,
                  nodes: [...(previousConnection?.nodes ?? []), ...newConnection.nodes],
                },
              },
            };
          },
        })
        .catch((error) => {
          this.loadMoreError = true;
          Sentry.captureException(error);
        })
        .finally(() => {
          this.fetchNextPageInProgress = false;
        });
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-shrink-0 gl-flex-col gl-rounded-xl gl-bg-strong dark:gl-bg-subtle"
    :class="[
      collapsed ? 'gl-w-8 gl-self-start' : 'gl-h-full gl-w-48',
      { 'gl-cursor-not-allowed gl-opacity-5': dropDisabled },
    ]"
  >
    <column-header
      :value="value"
      :decoration="decoration"
      :count="totalCount"
      :collapsed="collapsed"
      :controls-id="columnBodyId"
      @toggle-collapse="$emit('toggle-collapse')"
    />
    <div
      v-show="!collapsed"
      :id="columnBodyId"
      class="gl-flex gl-min-h-0 gl-flex-1 gl-flex-col gl-overflow-y-auto gl-px-3 gl-pb-3"
    >
      <p
        v-if="error"
        data-testid="error-state"
        class="gl-py-3 gl-text-center gl-text-sm gl-text-subtle"
      >
        {{ error }}
      </p>
      <!-- Always rendered (outside the error state) so an empty column stays a drop target. -->
      <draggable-compat
        v-else
        :value="workItems"
        item-key="id"
        tag="ul"
        :data-group-value-id="value.id"
        v-bind="$options.sortableOptions"
        :group="groupConfig"
        :disabled="dragDisabled"
        class="gl-m-0 gl-flex gl-flex-1 gl-list-none gl-flex-col gl-gap-3 gl-p-0"
        @start="onDragStart"
        @end="$emit('card-move', $event)"
      >
        <work-item-card
          v-for="workItem in workItems"
          :key="workItem.id"
          :item="workItem"
          :hidden-metadata-keys="hiddenMetadataKeys"
          :root-page-full-path="rootPageFullPath"
          :active-item="activeItem"
          :detail-panel-enabled="detailPanelEnabled"
          @set-active-item="$emit('set-active-item', $event)"
        />
        <work-item-card-skeleton
          v-for="n in isLoading || fetchNextPageInProgress ? $options.skeletonCount : 0"
          :key="`skeleton-${n}`"
        />
        <li
          v-if="showEmptyState"
          data-testid="empty-state"
          class="gl-list-none gl-py-3 gl-text-center gl-text-sm gl-text-subtle"
        >
          {{ $options.i18n.emptyText }}
        </li>
        <li v-if="hasNextPage && !fetchNextPageInProgress" class="gl-list-none">
          <work-item-children-load-more
            class="gl-justify-center"
            :fetch-next-page-in-progress="fetchNextPageInProgress"
            @fetch-next-page="fetchNextPage"
          />
        </li>
        <li
          v-if="loadMoreError"
          data-testid="load-more-error"
          class="gl-list-none gl-py-2 gl-text-center gl-text-sm gl-text-subtle"
        >
          {{ $options.i18n.loadMoreError }}
        </li>
      </draggable-compat>
    </div>
  </div>
</template>
