<script>
import { GlIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DraggableCompat from '~/lib/utils/vue3compat/draggable_compat.vue';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';
import { sortableStart, sortableEnd } from '~/sortable/utils';
import WorkItemChildrenLoadMore from '~/work_items/components/shared/work_item_children_load_more.vue';
import { DEFAULT_PAGE_SIZE_BOARD_COLUMN_SUBSEQUENT } from '~/work_items/constants';
import { getWorkItemsConnection } from '~/work_items/utils';

import { boardColumnQuery, boardColumnQueryVariables } from '../utils';
import {
  BOARD_DND_GROUP,
  BOARD_CARD_CLASS,
  BOARD_CARD_DROP_INDICATOR_CLASS,
  BOARD_CARD_NO_DRAG_CLASS,
} from '../constants';
import ColumnHeader from './column_header.vue';
import WorkItemCard from './work_item_card.vue';
import WorkItemCardSkeleton from './work_item_card_skeleton.vue';

export default {
  name: 'BoardColumn',
  skeletonCount: 3,
  sortableOptions: {
    ...defaultSortableOptions,
    draggable: `.${BOARD_CARD_CLASS}`,
    ghostClass: BOARD_CARD_DROP_INDICATOR_CLASS,
    filter: `.${BOARD_CARD_NO_DRAG_CLASS}`,
    preventOnFilter: false,
    delay: DRAG_DELAY,
    delayOnTouchOnly: true,
  },
  i18n: {
    emptyText: s__('WorkItemBoard|No items'),
    dropText: s__('WorkItemBoard|Drop here to move item.'),
    fetchError: s__('WorkItemBoard|An error occurred while fetching work items for this column.'),
    loadMoreError: s__('WorkItemBoard|An error occurred while fetching more work items.'),
    loadMoreLabel: s__('WorkItemBoard|Load more %{listName} list items'),
  },
  components: {
    ColumnHeader,
    DraggableCompat,
    GlIcon,
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
    count: {
      type: Number,
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
    focusCreateButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    insertingCard: {
      type: Boolean,
      required: false,
      default: false,
    },
    canReorderCards: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: [
    'card-move',
    'card-move-to-position',
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
      error: null,
      loadMoreError: false,
      loadMoreErrorFocusable: false,
      fetchNextPageInProgress: false,
      columnBodyId: uniqueId('board-column-body-'),
      isDropTarget: false,
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
        groupFilter: this.strategy.groupFilter(this.value),
      });
    },
    loadMoreLabel() {
      return sprintf(this.$options.i18n.loadMoreLabel, { listName: this.value.name }, false);
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
    columnClasses() {
      return [
        this.collapsed ? 'gl-w-[2.75rem] gl-self-start' : 'gl-h-full gl-w-48',
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
  },
  mounted() {
    // SortableJS inserts the drop indicator outside Vue's render, so watch the DOM for it.
    this.dropTargetObserver = new MutationObserver(() => {
      this.isDropTarget =
        this.showEmptyState &&
        Boolean(this.$refs.columnBody.querySelector(`.${BOARD_CARD_DROP_INDICATOR_CLASS}`));
    });
    this.dropTargetObserver.observe(this.$refs.columnBody, { childList: true, subtree: true });
  },
  beforeDestroy() {
    this.dropTargetObserver.disconnect();
  },
  methods: {
    onDragStart(evt) {
      sortableStart();
      const workItemId = evt.item?.dataset?.workItemId;
      this.$emit(
        'drag-start',
        this.workItems.find((workItem) => workItem.id === workItemId),
      );
    },
    onDragEnd(evt) {
      // `end` fires for aborted drops too, so this is the only place we can
      // reliably clean up the body class `sortableStart` added.
      sortableEnd();
      this.$emit('card-move', evt);
    },
    moveCardToPosition(oldIndex, newIndex) {
      this.$emit('card-move-to-position', {
        workItemId: this.workItems[oldIndex]?.id,
        oldIndex,
        newIndex,
      });
    },
    fetchNextPage() {
      if (!this.hasNextPage || this.fetchNextPageInProgress) {
        return Promise.resolve(null);
      }

      this.fetchNextPageInProgress = true;
      this.loadMoreError = false;
      let firstNewId = null;

      return this.$apollo.queries.workItemsConnection
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

            firstNewId = newConnection.nodes[0]?.id ?? null;

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
        .then(() => ({ firstNewId }))
        .catch((error) => {
          this.loadMoreError = true;
          Sentry.captureException(error);
          return { firstNewId: null };
        })
        .finally(() => {
          this.fetchNextPageInProgress = false;
        });
    },
    async onLoadMore() {
      const result = await this.fetchNextPage();
      if (!result) {
        return;
      }
      await this.$nextTick();

      // The button unmounts while loading, so focus is on body. Leave it alone if the
      // user moved it out of this column in the meantime.
      const { activeElement } = document;
      if (activeElement && activeElement !== document.body && !this.$el.contains(activeElement)) {
        return;
      }

      if (this.loadMoreError) {
        await this.focusLoadMoreError();
        return;
      }

      const target =
        this.findCardLink(result.firstNewId) ||
        this.$refs.loadMoreItem?.querySelector('button') ||
        this.findCardLink(this.workItems.at(-1)?.id);
      target?.focus();
    },
    async focusLoadMoreError() {
      this.loadMoreErrorFocusable = true;
      await this.$nextTick();
      this.$refs.loadMoreErrorAlert?.focus();
      this.$refs.loadMoreErrorAlert?.scrollIntoView({ block: 'nearest' });
    },
    findCardLink(workItemId) {
      return workItemId ? this.$el.querySelector(`[data-work-item-id="${workItemId}"] > a`) : null;
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
      :count="count"
      :collapsed="collapsed"
      :controls-id="columnBodyId"
      :reorderable="reorderable"
      :can-move-left="canMoveLeft"
      :can-move-right="canMoveRight"
      :can-hide="canHide"
      :can-create-work-item="canCreateWorkItem"
      :focus-create-button="focusCreateButton"
      @toggle-collapse="$emit('toggle-collapse')"
      @move-column="$emit('move-column', $event)"
      @hide-column="$emit('hide-column')"
      @create-item="$emit('create-item', value)"
    />
    <div
      v-show="!collapsed"
      :id="columnBodyId"
      ref="columnBody"
      class="gl-flex gl-min-h-0 gl-flex-1 gl-flex-col gl-overflow-y-auto gl-overflow-x-hidden gl-px-3 gl-pb-3"
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
        :data-column-value-id="value.id"
        :aria-label="value.name"
        v-bind="$options.sortableOptions"
        :group="groupConfig"
        :disabled="dragDisabled"
        class="board-card-list gl-m-0 gl-flex gl-flex-1 gl-list-none gl-flex-col gl-gap-3 gl-p-0"
        :class="{ 'is-drop-target': isDropTarget }"
        @start="onDragStart"
        @end="onDragEnd"
      >
        <!-- Only the cards belong in the default slot: vuedraggable draws one node per
        item from it, and takes everything else through header and footer. -->
        <template #header>
          <work-item-card-skeleton v-if="insertingCard" />
        </template>
        <work-item-card
          v-for="(workItem, index) in workItems"
          :key="workItem.id"
          :item="workItem"
          :hidden-metadata-keys="hiddenMetadataKeys"
          :root-page-full-path="rootPageFullPath"
          :active-item="activeItem"
          :detail-panel-enabled="detailPanelEnabled"
          :can-reorder="canReorderCards"
          :is-first="index === 0"
          :is-last="index === workItems.length - 1"
          @set-active-item="$emit('set-active-item', $event)"
          @move-to-start="moveCardToPosition(index, 0)"
          @move-to-end="moveCardToPosition(index, workItems.length - 1)"
        />
        <template #footer>
          <work-item-card-skeleton
            v-for="n in isLoading || fetchNextPageInProgress ? $options.skeletonCount : 0"
            :key="`skeleton-${n}`"
          />
          <li
            v-if="showEmptyState"
            data-testid="empty-state"
            :data-drop-text="$options.i18n.dropText"
            class="board-column-empty-state gl-flex gl-flex-1 gl-list-none gl-flex-col gl-items-center gl-justify-center gl-gap-3 gl-text-subtle"
          >
            <gl-icon name="work-items" :size="24" />
            <span>{{ $options.i18n.emptyText }}</span>
          </li>
          <li
            v-if="hasNextPage && !fetchNextPageInProgress"
            ref="loadMoreItem"
            class="gl-list-none"
          >
            <work-item-children-load-more
              class="gl-justify-center"
              :fetch-next-page-in-progress="fetchNextPageInProgress"
              :aria-label="loadMoreLabel"
              @fetch-next-page="onLoadMore"
            />
          </li>
          <li
            v-if="loadMoreError"
            data-testid="load-more-error"
            class="gl-list-none gl-py-2 gl-text-center gl-text-sm gl-text-subtle"
          >
            <div
              ref="loadMoreErrorAlert"
              role="alert"
              :tabindex="loadMoreErrorFocusable ? -1 : null"
              @blur="loadMoreErrorFocusable = false"
            >
              {{ $options.i18n.loadMoreError }}
            </div>
          </li>
        </template>
      </draggable-compat>
    </div>
  </div>
</template>
