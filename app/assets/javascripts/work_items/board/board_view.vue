<script>
import { GlLoadingIcon, GlToastMixin } from '@gitlab/ui';
import { omit } from 'lodash-es';
import { __, s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { InternalEvents } from '~/tracking';
import { getParameterByName } from '~/lib/utils/url_utility';
import DraggableCompat from '~/lib/utils/vue3compat/draggable_compat.vue';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';
import { getDraft, updateDraft } from '~/lib/utils/autosave';
import {
  CREATION_CONTEXT_BOARD,
  DETAIL_VIEW_QUERY_PARAM_NAME,
  ROUTES,
  WORK_ITEM_CREATE_SOURCES,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
} from '~/work_items/constants';
import { RELATIVE_POSITION_ASC } from '~/work_items/list/constants';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';

import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import {
  findDetailPanelWorkItem,
  getNewWorkItemWidgetsAutoSaveKey,
  getWorkItemsConnection,
} from '../utils';
import updateBoardWorkItemMutation from './graphql/update_board_work_item.mutation.graphql';
import { DEFAULT_GROUP_BY, groupingStrategyFor } from './grouping';
import { SHOW_ALL_GROUPS, toggleGroupVisibility } from './grouping/visibility';
import { orderGroups, reorderGroupIds } from './grouping/ordering';
import workItemsGroupByVisibleGroupsQuery from './grouping/graphql/client/visible_groups.query.graphql';
import updateVisibleGroupsMutation from './grouping/graphql/client/update_visible_groups.mutation.graphql';
import {
  boardColumnQuery,
  boardColumnQueryVariables,
  boardColumnCountVariables,
  getGroupId,
  getGroupValueId,
  getMovePositionIds,
} from './utils';
import {
  addWorkItemToColumn,
  adjustWorkItemCountInColumn,
  readWorkItemFromColumn,
  readWorkItemsFromColumn,
  removeWorkItemFromColumn,
} from './graphql/cache_updates';
import {
  I18N_MOVE_ERROR,
  I18N_MOVE_SUCCESS,
  MOVE_IN_PROGRESS_INDICATOR_DELAY,
  BOARD_COLUMN_DND_GROUP,
  BOARD_COLUMN_CLASS,
  BOARD_COLUMN_DRAG_HANDLE_CLASS,
  BOARD_COLUMN_NO_DRAG_CLASS,
} from './constants';
import { INHERITED_WIDGET_TYPES, resolveInheritedWidgetsDraft } from './filter_inheritance';
import ColumnGroup from './components/column_group.vue';

export default {
  name: 'BoardView',
  CREATION_CONTEXT_BOARD,
  WORK_ITEM_CREATE_SOURCES,
  components: {
    GlLoadingIcon,
    ColumnGroup,
    DraggableCompat,
    CreateWorkItemModal,
  },
  columnClass: BOARD_COLUMN_CLASS,
  columnDndGroup: { name: BOARD_COLUMN_DND_GROUP },
  columnSortableOptions: {
    ...defaultSortableOptions,
    draggable: `.${BOARD_COLUMN_CLASS}`,
    handle: `.${BOARD_COLUMN_DRAG_HANDLE_CLASS}`,
    filter: `.${BOARD_COLUMN_NO_DRAG_CLASS}`,
    preventOnFilter: false,
    delay: DRAG_DELAY,
    delayOnTouchOnly: true,
  },
  mixins: [glFeatureFlagMixin(), InternalEvents.mixin(), GlToastMixin],
  props: {
    rootPageFullPath: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
    collapsedGroups: {
      type: Array,
      required: false,
      default: () => [],
    },
    groupOrder: {
      type: Array,
      required: false,
      default: () => [],
    },
    canManageColumns: {
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
    updatedWorkItem: {
      type: Object,
      required: false,
      default: null,
    },
    preselectedWorkItemType: {
      type: String,
      required: false,
      default: null,
    },
    canCreateWorkItem: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: [
    'set-error',
    'set-active-item',
    'toggle-collapse',
    'reorder-groups',
    'hide-group',
    'work-item-created',
  ],
  data() {
    return {
      groupByValues: [],
      gateData: null,
      renderedColumns: [],
      // The column value a new item targets; also gates the create modal's
      // mount so it re-reads the freshly-seeded draft each time it opens.
      createColumnValue: null,
      workItemsGroupByVisibleGroups: SHOW_ALL_GROUPS,
      workItemsGroupByVisibleGroupsHydrated: false,
      // Column value ids the in-flight dragged item may not be dropped into.
      invalidValueIds: [],
      // Locks dragging while a move mutation is in flight so a second drop can't
      // compute before/after ids against a stale, not-yet-persisted order.
      moveInProgress: false,
      // Only shown once the lock above has been held for longer than
      // MOVE_IN_PROGRESS_INDICATOR_DELAY, so quick moves don't flash the columns.
      showMoveInProgressIndicator: false,
    };
  },
  computed: {
    groupBy() {
      return DEFAULT_GROUP_BY;
    },
    strategy() {
      return groupingStrategyFor(this.groupBy.property);
    },
    isLoading() {
      return this.$apollo.queries.groupByValues.loading;
    },
    // undefined (not null) omits the variable — Apollo treats null as a real value.
    idsToFetch() {
      if (this.workItemsGroupByVisibleGroups === SHOW_ALL_GROUPS) return undefined;
      return this.workItemsGroupByVisibleGroups
        .map((groupId) => getGroupValueId({ groupBy: this.groupBy, groupId }))
        .filter((valueId) => valueId !== null);
    },
    columnQuery() {
      return boardColumnQuery(this.glFeatures);
    },
    useRestApi() {
      return this.glFeatures.workItemRestApiFrontendUsers;
    },
    // Relative position is only meaningful under Manual sort; any other sort would
    // immediately override a reorder, so we don't persist position then.
    isManualSort() {
      return this.queryVariables.sort === RELATIVE_POSITION_ASC;
    },
    // The fetch is already scoped to the selected groups, so no client-side filtering
    // is needed here — just apply the persisted column order. Reconciling on read:
    // unknown/new groups fall to the end in default order, stale ids are ignored
    // (see `grouping/ordering.js`).
    orderedGroupByValues() {
      return orderGroups({
        groupOrder: this.groupOrder,
        groupBy: this.groupBy,
        values: this.groupByValues,
      });
    },
    // Reordering needs a user who can persist it and more than one column to move.
    canReorderColumns() {
      return this.canManageColumns && this.orderedGroupByValues.length > 1;
    },
    // Epics are a fixed type on their board, so the type selector is hidden there.
    alwaysShowWorkItemTypeSelect() {
      return this.preselectedWorkItemType !== WORK_ITEM_TYPE_NAME_EPIC;
    },
  },
  watch: {
    updatedWorkItem(workItem) {
      this.moveCardToMatchingColumn(workItem);
    },
    orderedGroupByValues: {
      immediate: true,
      handler(values) {
        this.renderedColumns = values;
      },
    },
  },
  mounted() {
    this.trackEvent('view_work_item_board', { label: this.groupBy.property });
  },
  apollo: {
    workItemsGroupByVisibleGroups: {
      query: workItemsGroupByVisibleGroupsQuery,
    },
    workItemsGroupByVisibleGroupsHydrated: {
      query: workItemsGroupByVisibleGroupsQuery,
    },
    groupByValues() {
      return {
        query: this.strategy?.valuesQuery,
        // Wait for hydration so the first fetch is already scoped, not fetch-then-refetch.
        skip() {
          return !this.strategy || !this.workItemsGroupByVisibleGroupsHydrated;
        },
        variables() {
          return { fullPath: this.rootPageFullPath, ids: this.idsToFetch };
        },
        update: (data) => this.strategy?.extractValues(data) ?? [],
        error: (error) => {
          this.$emit(
            'set-error',
            s__(
              'WorkItemBoard|Something went wrong when fetching the board columns. Please try again.',
            ),
          );
          Sentry.captureException(error);
        },
      };
    },
    gateData() {
      return {
        // A function so a falsy value here doesn't make vue-apollo treat this whole
        // options object as the query document; `skip` below is what gates the fetch.
        query() {
          return this.strategy?.gateQuery;
        },
        skip() {
          return !this.strategy?.gateQuery;
        },
        variables() {
          return { fullPath: this.rootPageFullPath };
        },
        update: (data) => this.strategy?.extractGateData?.(data) ?? null,
        error: (error) => {
          Sentry.captureException(error);
        },
      };
    },
  },
  methods: {
    groupId(value) {
      return getGroupId({ groupBy: this.groupBy, value });
    },
    // Pre-populates the new work item's widgets draft with the column's grouped attribute
    // (e.g. status) and the board's active filters (e.g. labels), then opens the create
    // modal for that column.
    async handleCreateItem(value) {
      const draftKey = getNewWorkItemWidgetsAutoSaveKey({
        fullPath: this.rootPageFullPath,
        context: CREATION_CONTEXT_BOARD,
      });
      const draft = JSON.parse(getDraft(draftKey) || '{}');
      const inheritedFilters = await resolveInheritedWidgetsDraft({
        apolloClient: this.$apollo.getClient(),
        fullPath: this.rootPageFullPath,
        isGroup: Boolean(this.queryVariables.isGroup),
        filters: this.queryVariables,
      });
      updateDraft(
        draftKey,
        JSON.stringify({
          // Drop previously-inherited widgets first: the draft is shared across board views,
          // so a filter that is no longer active must not linger from an earlier seeding.
          ...omit(draft, INHERITED_WIDGET_TYPES),
          ...(this.strategy?.newItemDraft(value) ?? {}),
          ...inheritedFilters,
        }),
      );
      this.createColumnValue = value;
    },
    async handleWorkItemCreated(workItem) {
      const clickedColumn = this.createColumnValue;
      this.createColumnValue = null;
      if (!workItem?.id || !workItem?.iid || !clickedColumn) {
        return;
      }

      // The item's grouping decides which column it belongs to but it can differ from the
      // clicked column if the user changed the grouped attribute (e.g. status) in the creation modal.
      const valueId = this.strategy?.itemValueId?.(workItem);
      const targetColumn = (valueId && this.valueById(valueId)) || clickedColumn;

      const shownOnBoard = await this.insertCreatedItemAtTop(workItem, targetColumn);
      this.showWorkItemCreatedToast(workItem, shownOnBoard);
      this.$emit('work-item-created', workItem);
    },
    async insertCreatedItemAtTop(workItem, column) {
      if (!column) {
        return false;
      }

      const client = this.$apollo.getClient();
      const query = this.columnQuery;
      const variables = this.columnVariables(column);

      try {
        const { data } = await client.query({
          query,
          variables: { ...variables, iid: workItem.iid, firstPageSize: 1 },
          fetchPolicy: 'no-cache',
        });
        const node = getWorkItemsConnection(data, this.useRestApi)?.nodes?.[0];
        if (!node) {
          return false;
        }

        const { cache } = client;
        const columnNodesBeforeInsert = this.isManualSort
          ? readWorkItemsFromColumn({ cache, query, variables, useRestApi: this.useRestApi })
          : [];

        addWorkItemToColumn({
          cache,
          query,
          variables,
          workItem: node,
          index: 0,
          useRestApi: this.useRestApi,
        });
        adjustWorkItemCountInColumn({
          cache,
          query: getWorkItemsCountOnlyQuery,
          variables: this.columnCountVariables(column),
          delta: 1,
        });

        if (columnNodesBeforeInsert?.length) {
          this.persistCreatedItemPosition({
            workItemId: workItem.id,
            nodes: columnNodesBeforeInsert,
          });
        }
        return true;
      } catch (error) {
        Sentry.captureException(error);
        return false;
      }
    },
    async persistCreatedItemPosition({ workItemId, nodes }) {
      const { moveBeforeId, moveAfterId } = getMovePositionIds({
        nodes,
        sameColumn: false,
        newIndex: 0,
      });
      if (!moveBeforeId && !moveAfterId) {
        return;
      }

      const input = { id: workItemId };
      if (moveBeforeId) {
        input.moveBeforeId = moveBeforeId;
      }
      if (moveAfterId) {
        input.moveAfterId = moveAfterId;
      }

      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateBoardWorkItemMutation,
          variables: { input },
        });
        if (data?.workItemUpdate?.errors?.length) {
          throw new Error(data.workItemUpdate.errors.join(', '));
        }
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    showWorkItemCreatedToast(workItem, shownOnBoard) {
      const workItemType =
        workItem?.workItemType?.name || this.preselectedWorkItemType || s__('WorkItem|Work item');
      const message = shownOnBoard
        ? sprintf(s__('WorkItem|%{workItemType} created.'), { workItemType })
        : sprintf(
            s__('WorkItem|%{workItemType} created, but it is not shown on the current view.'),
            { workItemType },
          );

      this.$toast.show(message, {
        autoHideDelay: 10000,
        action: {
          text: __('View details'),
          onClick: () => {
            this.$router?.push({
              name: ROUTES.workItem,
              params: { iid: workItem.iid, type: WORK_ITEM_TYPE_ROUTE_WORK_ITEM },
            });
          },
        },
      });
    },
    // Opens the detail panel for the item in the `show` param.
    // Each column loads separately, so we run this whenever one resolves. We don't clear
    // the param when the item is missing as it may still load in another column.
    checkDetailPanelParams(workItems) {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);
      if (!queryParam) {
        return;
      }

      const { item } = findDetailPanelWorkItem(queryParam, workItems, this.activeItem);
      if (item) {
        this.$emit('set-active-item', item);
      }
    },
    isColumnCollapsed(value) {
      return this.collapsedGroups.includes(this.groupId(value));
    },
    valueById(valueId) {
      return this.groupByValues.find(({ id }) => id === valueId) ?? null;
    },
    columnVariables(value) {
      return boardColumnQueryVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.queryVariables,
        columnFilter: this.strategy.columnFilter(value),
      });
    },
    columnCountVariables(value) {
      return boardColumnCountVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.queryVariables,
        columnFilter: this.strategy.columnFilter(value),
      });
    },
    // Shared method to move the card and adjust the work item count
    moveWorkItemBetweenColumns({
      cache,
      workItemId,
      node,
      fromColumn,
      toColumn,
      index,
      patchCard = null,
    }) {
      const query = this.columnQuery;

      removeWorkItemFromColumn({
        cache,
        query,
        variables: this.columnVariables(fromColumn),
        workItemId,
        useRestApi: this.useRestApi,
      });
      addWorkItemToColumn({
        cache,
        query,
        variables: this.columnVariables(toColumn),
        workItem: node,
        index,
        patchCard,
        useRestApi: this.useRestApi,
      });
      adjustWorkItemCountInColumn({
        cache,
        query: getWorkItemsCountOnlyQuery,
        variables: this.columnCountVariables(fromColumn),
        delta: -1,
      });
      adjustWorkItemCountInColumn({
        cache,
        query: getWorkItemsCountOnlyQuery,
        variables: this.columnCountVariables(toColumn),
        delta: 1,
      });
    },
    moveCardToMatchingColumn(workItem) {
      const workItemId = workItem?.id;
      if (!workItemId || !this.strategy?.itemValueId) {
        return;
      }

      const matchingColumn = this.valueById(this.strategy.itemValueId(workItem));
      if (!matchingColumn) {
        return;
      }

      const { cache } = this.$apollo.getClient();
      const query = this.columnQuery;

      const currentColumn = this.groupByValues.find((column) =>
        readWorkItemFromColumn({
          cache,
          query,
          variables: this.columnVariables(column),
          workItemId,
          useRestApi: this.useRestApi,
        }),
      );

      if (!currentColumn || currentColumn.id === matchingColumn.id) {
        return;
      }

      const node = readWorkItemFromColumn({
        cache,
        query,
        variables: this.columnVariables(currentColumn),
        workItemId,
        useRestApi: this.useRestApi,
      });

      this.moveWorkItemBetweenColumns({
        cache,
        workItemId,
        node,
        fromColumn: currentColumn,
        toColumn: matchingColumn,
        index: 0,
        patchCard: (draftNode) => this.strategy.patchCard(draftNode, matchingColumn),
      });
    },
    onDragStart(workItem) {
      this.invalidValueIds = this.groupByValues
        .filter((value) => !this.isDropAllowed({ item: workItem, value }))
        .map((value) => value.id);
    },
    moveColumn(oldIndex, newIndex) {
      if (
        oldIndex == null ||
        newIndex == null ||
        oldIndex === newIndex ||
        newIndex < 0 ||
        newIndex >= this.renderedColumns.length
      ) {
        return;
      }

      const reordered = [...this.renderedColumns];
      const [moved] = reordered.splice(oldIndex, 1);
      reordered.splice(newIndex, 0, moved);
      this.renderedColumns = reordered;

      this.$emit(
        'reorder-groups',
        reorderGroupIds({
          visibleValues: this.renderedColumns,
          groupBy: this.groupBy,
          currentOrder: this.groupOrder,
        }),
      );
    },
    onColumnMove({ oldIndex, newIndex }) {
      this.moveColumn(oldIndex, newIndex);
    },
    // `delta` is how many positions to shift by (-1 left, +1 right). moveColumn
    // ignores an out-of-range target, so edge columns are safe.
    onColumnShift({ value, delta }) {
      const oldIndex = this.renderedColumns.findIndex((column) => column.id === value.id);
      if (oldIndex === -1) {
        return;
      }
      this.moveColumn(oldIndex, oldIndex + delta);
    },
    async onColumnHide(value) {
      const visibleGroups = toggleGroupVisibility({
        visibleGroups: this.workItemsGroupByVisibleGroups,
        groupBy: this.groupBy,
        value,
        allValues: this.groupByValues,
      });

      try {
        await this.$apollo.mutate({
          mutation: updateVisibleGroupsMutation,
          variables: { visibleGroups },
          // See syncVisibleGroupsToCache in planning_view.vue: caching this client-only
          // mutation lets a later work item refetch overwrite unrelated edits.
          fetchPolicy: 'no-cache',
        });
      } catch (error) {
        Sentry.captureException(error);
        return;
      }

      this.$emit('hide-group', visibleGroups);
    },
    isDropAllowed({ item, value }) {
      return this.strategy?.isDropAllowed?.({ item, value, gateData: this.gateData }) ?? true;
    },
    async onCardMove({ from, to, item, oldIndex, newIndex }) {
      this.invalidValueIds = [];
      const fromValueId = from?.dataset?.groupValueId;
      const toValueId = to?.dataset?.groupValueId;
      const workItemId = item?.dataset?.workItemId;

      if (!fromValueId || !toValueId || !workItemId) {
        return;
      }

      const fromValue = this.valueById(fromValueId);
      const toValue = this.valueById(toValueId);
      if (!fromValue || !toValue) {
        return;
      }

      // Columns are grouped values, so an unchanged value means a same-column reorder.
      const valueChanged = fromValueId !== toValueId;

      const { cache } = this.$apollo.getClient();
      const query = this.columnQuery;
      const fromVariables = this.columnVariables(fromValue);
      const toVariables = this.columnVariables(toValue);

      // Relative position comes from the target column's pre-move order so the
      // before/after ids match where the card lands. Only computed under Manual sort.
      const { moveBeforeId, moveAfterId } = this.isManualSort
        ? getMovePositionIds({
            nodes: readWorkItemsFromColumn({
              cache,
              query,
              variables: toVariables,
              useRestApi: this.useRestApi,
            }),
            sameColumn: !valueChanged,
            oldIndex,
            newIndex,
          })
        : {};

      // Nothing to persist: dropped back in place with no value or position change.
      if (!valueChanged && !moveBeforeId && !moveAfterId) {
        return;
      }

      // Snapshot the moved card so the cache update can reinsert it into the target
      // column (with the new value) on both the optimistic and the confirmed pass.
      const node = readWorkItemFromColumn({
        cache,
        query,
        variables: fromVariables,
        workItemId,
        useRestApi: this.useRestApi,
      });
      if (!node) {
        return;
      }

      const input = { id: workItemId };
      if (valueChanged) {
        Object.assign(input, this.strategy.moveInput(toValue));
      }
      if (moveBeforeId) {
        input.moveBeforeId = moveBeforeId;
      }
      if (moveAfterId) {
        input.moveAfterId = moveAfterId;
      }

      this.moveInProgress = true;
      const indicatorTimer = setTimeout(() => {
        this.showMoveInProgressIndicator = true;
      }, MOVE_IN_PROGRESS_INDICATOR_DELAY);
      try {
        // Apollo runs `update` optimistically, then again on the server result; a
        // failure discards the optimistic layer and snaps the card back. We reinsert
        // the cached `node` (it has the display fields) rather than the id-only payload.
        const { data } = await this.$apollo.mutate({
          mutation: updateBoardWorkItemMutation,
          variables: { input },
          optimisticResponse: {
            workItemUpdate: {
              __typename: 'WorkItemUpdatePayload',
              workItem: { __typename: 'WorkItem', id: workItemId },
              errors: [],
            },
          },
          update: (store, { data: { workItemUpdate } }) => {
            if (!workItemUpdate?.workItem) {
              return;
            }

            this.moveWorkItemBetweenColumns({
              cache: store,
              workItemId,
              node,
              fromColumn: fromValue,
              toColumn: toValue,
              index: newIndex,
              // Only patch the card on a cross-column move; a reorder keeps its value.
              patchCard: valueChanged
                ? (draftNode) => this.strategy.patchCard(draftNode, toValue)
                : null,
            });
          },
        });

        if (data?.workItemUpdate?.errors?.length) {
          throw new Error(data.workItemUpdate.errors.join(', '));
        }

        if (valueChanged) {
          this.$toast.show(
            sprintf(I18N_MOVE_SUCCESS, { reference: node.reference, targetGroup: toValue.name }),
          );
        }
      } catch (error) {
        this.$toast.show(I18N_MOVE_ERROR);
        Sentry.captureException(error);
      } finally {
        clearTimeout(indicatorTimer);
        this.moveInProgress = false;
        this.showMoveInProgressIndicator = false;
      }
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-w-full gl-overflow-x-auto gl-py-5"
    style="height: calc(100dvh - 220px - 2rem)"
  >
    <gl-loading-icon v-if="isLoading && groupByValues.length === 0" size="lg" class="gl-m-auto" />
    <draggable-compat
      v-else
      :value="renderedColumns"
      item-key="id"
      tag="div"
      class="gl-flex gl-h-full gl-w-full gl-gap-3"
      v-bind="$options.columnSortableOptions"
      :group="$options.columnDndGroup"
      :disabled="!canReorderColumns"
      @end="onColumnMove"
    >
      <column-group
        v-for="(value, index) in renderedColumns"
        :key="value.id"
        :class="$options.columnClass"
        :value="value"
        :strategy="strategy"
        :root-page-full-path="rootPageFullPath"
        :base-query-variables="queryVariables"
        :drag-disabled="moveInProgress"
        :show-busy-indicator="showMoveInProgressIndicator"
        :drop-disabled="invalidValueIds.includes(value.id)"
        :collapsed="isColumnCollapsed(value)"
        :reorderable="canReorderColumns"
        :can-move-left="index > 0"
        :can-move-right="index < renderedColumns.length - 1"
        :can-hide="canManageColumns"
        :can-create-work-item="canCreateWorkItem"
        :hidden-metadata-keys="hiddenMetadataKeys"
        :active-item="activeItem"
        :detail-panel-enabled="detailPanelEnabled"
        @drag-start="onDragStart"
        @card-move="onCardMove"
        @move-column="onColumnShift({ value, delta: $event })"
        @hide-column="onColumnHide(value)"
        @set-active-item="$emit('set-active-item', $event)"
        @check-board-params="checkDetailPanelParams"
        @toggle-collapse="$emit('toggle-collapse', groupId(value))"
        @create-item="handleCreateItem"
      />
    </draggable-compat>
    <create-work-item-modal
      v-if="createColumnValue"
      visible
      hide-button
      :always-show-work-item-type-select="alwaysShowWorkItemTypeSelect"
      :creation-context="$options.CREATION_CONTEXT_BOARD"
      :full-path="rootPageFullPath"
      :is-group="queryVariables.isGroup"
      :preselected-work-item-type="preselectedWorkItemType"
      :create-source="$options.WORK_ITEM_CREATE_SOURCES.WORK_ITEM_BOARD"
      suppress-created-toast
      @work-item-created="handleWorkItemCreated"
      @hide-modal="createColumnValue = null"
    />
  </div>
</template>
