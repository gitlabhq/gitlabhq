<script>
import { uniqueId } from 'lodash-es';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DraggableCompat from '~/lib/utils/vue3compat/draggable_compat.vue';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';
import WorkItemChildrenLoadMore from '~/work_items/components/shared/work_item_children_load_more.vue';
import { DEFAULT_PAGE_SIZE_BOARD_COLUMN_SUBSEQUENT } from '~/work_items/constants';
import { getWorkItemsConnection } from '~/work_items/utils';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';

import { boardColumnQuery, boardColumnQueryVariables, boardColumnCountVariables } from '../utils';
import { BOARD_DND_GROUP, BOARD_CARD_CLASS } from '../constants';
import ColumnHeader from './column_header.vue';
import WorkItemCard from './work_item_card.vue';
import WorkItemCardSkeleton from './work_item_card_skeleton.vue';

export default {
  name: 'ColumnGroup',
  skeletonCount: 3,
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
    showBusyIndicator: {
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
    reorderable: {
      type: Boolean,
      required: false,
      default: false,
    },
    canMoveLeft: {
      type: Boolean,
      required: false,
      default: false,
    },
    canMoveRight: {
      type: Boolean,
      required: false,
      default: false,
    },
    canHide: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateWorkItem: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: [
    'card-move',
    'set-active-item',
    'toggle-collapse',
    'drag-start',
    'check-board-params',
    'move-column',
    'hide-column',
    'create-item',
  ],
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
    useRestApi() {
      return this.glFeatures.workItemRestApiFrontendUsers;
    },
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
      // sortablejs's `put` decides which groups are allowed to drop cards into
      // this list. Setting it to `true` sounds harmless, but sortablejs reads
      // that as "accept literally anything". So we only allow this column's
      // own card group in, and set `put: false` here to reject drops the
      // strategy has flagged as invalid for this item.
      return { name: BOARD_DND_GROUP, put: this.dropDisabled ? false : [BOARD_DND_GROUP] };
    },
    countQueryVariables() {
      return boardColumnCountVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.baseQueryVariables,
        columnFilter: this.strategy.columnFilter(this.value),
      });
    },
    columnClasses() {
      return [
        this.collapsed ? 'gl-w-8 gl-self-start' : 'gl-h-full gl-w-48',
        {
          'gl-opacity-5': this.dropDisabled || this.showBusyIndicator,
          'gl-cursor-not-allowed': this.dropDisabled,
          'gl-cursor-wait': this.showBusyIndicator && !this.dropDisabled,
        },
      ];
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
          return getWorkItemsConnection(data, this.useRestApi) ?? { nodes: [], pageInfo: {} };
        },
        result({ data, error }) {
          if (!error) {
            this.error = null;
          }
          this.$emit(
            'check-board-params',
            getWorkItemsConnection(data, this.useRestApi)?.nodes ?? [],
          );
        },
        variables() {
          return this.queryVariables;
        },
        error(error) {
          // If pagination fails, fetchNextPage shows the error inline and keeps
          // whatever already loaded on screen. Only the initial load replaces the
          // whole column with an error state.
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
          updateQuery: (previousResult, { fetchMoreResult }) => {
            const previousConnection = getWorkItemsConnection(previousResult, this.useRestApi);
            const newConnection = getWorkItemsConnection(fetchMoreResult, this.useRestApi);

            if (!newConnection) {
              return previousResult;
            }

            if (this.useRestApi) {
              return {
                ...fetchMoreResult,
                restWorkItems: {
                  ...newConnection,
                  nodes: [...(previousConnection?.nodes ?? []), ...newConnection.nodes],
                },
              };
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
    :class="columnClasses"
    :aria-busy="showBusyIndicator"
  >
    <column-header
      :value="value"
      :decoration="decoration"
      :count="totalCount"
      :collapsed="collapsed"
      :controls-id="columnBodyId"
      :reorderable="reorderable"
      :can-move-left="canMoveLeft"
      :can-move-right="canMoveRight"
      :can-hide="canHide"
      :can-create-work-item="canCreateWorkItem"
      @toggle-collapse="$emit('toggle-collapse')"
      @move-column="$emit('move-column', $event)"
      @hide-column="$emit('hide-column')"
      @create-item="$emit('create-item', value)"
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
      <!-- Rendered whenever the column is expanded, even if empty, so it stays a valid
      drop target. Not rendered while collapsed, so dragging the column doesn't drag its
      cards along with it. The wrapper div stays in the DOM either way (via v-show) so
      the header's aria-controls keeps pointing at a real element. -->
      <draggable-compat
        v-else-if="!collapsed"
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
