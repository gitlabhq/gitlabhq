<script>
import { GlButton, GlEmptyState, GlLoadingIcon, GlToastMixin } from '@gitlab/ui';
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
import { DEFAULT_GROUP_BY, groupingStrategyFor, getGroupId, getGroupValueId } from './grouping';
import {
  MAX_VISIBLE_GROUPS,
  SHOW_ALL_GROUPS,
  exceedsGroupLimit,
  toggleGroupVisibility,
} from './grouping/visibility';
import { orderGroups, reorderGroupIds } from './grouping/ordering';
import workItemsGroupByVisibleGroupsQuery from './grouping/graphql/client/visible_groups.query.graphql';
import updateVisibleGroupsMutation from './grouping/graphql/client/update_visible_groups.mutation.graphql';
import {
  boardColumnQuery,
  boardColumnQueryVariables,
  boardColumnCountVariables,
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
import BoardColumn from './components/board_column.vue';

export default {
  name: 'BoardView',
  CREATION_CONTEXT_BOARD,
  WORK_ITEM_CREATE_SOURCES,
  components: {
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
    BoardColumn,
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
  i18n: {
    groupSelectionTitle: s__('WorkItemBoard|Choose which groups to show'),
    chooseGroups: s__('WorkItemBoard|Choose groups'),
    groupSelectionPromptDescription: s__(
      'WorkItemBoard|Boards show up to %{maxGroups} groups at a time, choose groups to build your board.',
    ),
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
    hasActiveFilters: {
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
    'open-group-by-settings',
  ],
  data() {
    return {
      groupValues: [],
      gateData: null,
      renderedColumns: [],
      // The column value a new item targets; also gates the create modal's
      // mount so it re-reads the freshly-seeded draft each time it opens.
      createColumnValue: null,
      workItemsGroupByVisibleGroups: SHOW_ALL_GROUPS,
      workItemsGroupByVisibleGroupsHydrated: false,
      // Columns the dragged item can't be dropped into.
      invalidValueIds: [],
      // Lock dragging while a move is saving, so the next drop doesn't land based
      // on an order the server hasn't saved yet.
      moveInProgress: false,
      // Only true once the lock above has been held longer than
      // MOVE_IN_PROGRESS_INDICATOR_DELAY, so a quick move doesn't flash the columns grey.
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
      return this.$apollo.queries.groupValues.loading;
    },
    noGroupsSelected() {
      return (
        Array.isArray(this.workItemsGroupByVisibleGroups) &&
        this.workItemsGroupByVisibleGroups.length === 0
      );
    },
    // Returning undefined (not null) skips the ids variable, since Apollo treats null as a
    // real filter. Skip it the same way when nothing's selected, so the fetch stays unfiltered
    // and groupValues still reports the true group count (see groupSelectionPromptDescription).
    idsToFetch() {
      if (this.workItemsGroupByVisibleGroups === SHOW_ALL_GROUPS || this.noGroupsSelected) {
        return undefined;
      }
      return this.workItemsGroupByVisibleGroups
        .map((groupId) => getGroupValueId({ groupBy: this.groupBy, groupId }))
        .filter((valueId) => valueId !== null);
    },
    tooManyGroups() {
      return exceedsGroupLimit(this.groupValues.length);
    },
    needsGroupSelection() {
      return this.tooManyGroups || this.noGroupsSelected;
    },
    groupSelectionPromptDescription() {
      return sprintf(this.$options.i18n.groupSelectionPromptDescription, {
        maxGroups: MAX_VISIBLE_GROUPS,
      });
    },
    columnQuery() {
      return boardColumnQuery(this.glFeatures);
    },
    useRestApi() {
      return this.glFeatures.workItemRestApiFrontendUsers;
    },
    // Relative position only means anything under Manual sort — any other sort
    // would immediately override a reorder, so we don't bother persisting it then.
    isManualSort() {
      return this.queryVariables.sort === RELATIVE_POSITION_ASC;
    },
    // Already scoped to the selected groups server-side, so just apply the
    // persisted column order (grouping/ordering.js sends new groups to the end
    // and drops stale ids).
    orderedGroupValues() {
      return orderGroups({
        groupOrder: this.groupOrder,
        groupBy: this.groupBy,
        values: this.groupValues,
      });
    },
    canReorderColumns() {
      return this.canManageColumns && this.orderedGroupValues.length > 1;
    },
    // Epics are a fixed type on their board, so the type selector is hidden there.
    alwaysShowWorkItemTypeSelect() {
      return this.preselectedWorkItemType !== WORK_ITEM_TYPE_NAME_EPIC;
    },
    inheritedConfidential() {
      return this.queryVariables.confidential === true;
    },
  },
  watch: {
    updatedWorkItem(workItem) {
      this.syncCardWithBoard(workItem);
    },
    orderedGroupValues: {
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
    groupValues() {
      return {
        query: this.strategy?.valuesQuery,
        // Waits for hydration so the first fetch is already scoped, not fetch-then-refetch.
        // It's safe to fetch everything when nothing's selected too, since columns don't
        // render until a selection is made, so this can't render too many columns.
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
        // This has to be a function. If we just put a possibly-falsy value here,
        // vue-apollo would treat this whole options object as the query document
        // instead. `skip` below is what actually decides whether to fetch.
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
    // Fills in the new item's draft with the column's grouped attribute (e.g.
    // status) and the board's active filters (e.g. labels), then opens the
    // create modal for that column.
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
          // Drop whatever was inherited last time first. The draft is shared across
          // board views, so a filter that's no longer active shouldn't linger.
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

      // The item's grouped attribute decides which column it actually belongs to,
      // which can differ from the clicked column if the user changed it (e.g.
      // status) while filling in the creation modal.
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
    // Each column loads separately, so this runs every time one resolves. If the
    // item isn't in this batch we leave the param alone, since it may still turn
    // up in another column.
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
      return this.groupValues.find(({ id }) => id === valueId) ?? null;
    },
    columnVariables(value) {
      return boardColumnQueryVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.queryVariables,
        groupFilter: this.strategy.groupFilter(value),
      });
    },
    columnCountVariables(value) {
      return boardColumnCountVariables({
        rootPageFullPath: this.rootPageFullPath,
        baseQueryVariables: this.queryVariables,
        groupFilter: this.strategy.groupFilter(value),
      });
    },
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

      const currentColumn = this.groupValues.find((value) =>
        readWorkItemFromColumn({
          cache,
          query,
          variables: this.columnVariables(value),
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
    syncCardWithBoard(workItem) {
      if (!workItem?.id || !this.strategy?.itemValueId) {
        return;
      }

      if (this.hasActiveFilters) {
        this.reconcileFilteredCard(workItem);
        return;
      }

      this.moveCardToMatchingColumn(workItem);
    },
    // Fetches the item scoped to a column's filters so the server decides whether it
    // still matches the board. Returns the node when it matches, null when it's
    // excluded (or absent), and undefined when the check itself failed — so the caller
    // can tell a confirmed "no longer matches" apart from a transient error.
    async fetchColumnItem(workItem, column) {
      try {
        const { data } = await this.$apollo.getClient().query({
          query: this.columnQuery,
          variables: { ...this.columnVariables(column), iid: workItem.iid, firstPageSize: 1 },
          fetchPolicy: 'no-cache',
        });
        return data?.namespace?.workItems?.nodes?.[0] ?? null;
      } catch (error) {
        Sentry.captureException(error);
        return undefined;
      }
    },
    async reconcileFilteredCard(workItem) {
      const workItemId = workItem.id;
      const { cache } = this.$apollo.getClient();
      const query = this.columnQuery;

      const currentColumn = this.groupValues.find((column) =>
        readWorkItemFromColumn({
          cache,
          query,
          variables: this.columnVariables(column),
          workItemId,
        }),
      );

      const matchingColumn = this.valueById(this.strategy.itemValueId(workItem));
      const validWorkItem = matchingColumn
        ? await this.fetchColumnItem(workItem, matchingColumn)
        : null;

      // The filter check failed (undefined) rather than confirming an exclusion; leave
      // the board as-is instead of dropping a still-valid card.
      if (validWorkItem === undefined) {
        return;
      }

      // A newer update arrived while we were fetching (the watcher only fires on a new
      // prop reference); let its reconcile win rather than applying this stale result.
      if (this.updatedWorkItem !== workItem) {
        return;
      }

      if (!validWorkItem) {
        if (currentColumn) {
          this.removeCardFromColumn(workItemId, currentColumn);
        }
        return;
      }

      // Matches the filters but isn't on the board (e.g. re-added after being filtered out).
      if (!currentColumn) {
        this.addCardToColumn(validWorkItem, matchingColumn);
        return;
      }

      if (currentColumn.id === matchingColumn.id) {
        return;
      }

      this.moveWorkItemBetweenColumns({
        cache,
        workItemId,
        node: validWorkItem,
        fromColumn: currentColumn,
        toColumn: matchingColumn,
        index: 0,
      });
    },
    removeCardFromColumn(workItemId, column) {
      const { cache } = this.$apollo.getClient();
      removeWorkItemFromColumn({
        cache,
        query: this.columnQuery,
        variables: this.columnVariables(column),
        workItemId,
      });
      adjustWorkItemCountInColumn({
        cache,
        query: getWorkItemsCountOnlyQuery,
        variables: this.columnCountVariables(column),
        delta: -1,
      });
    },
    addCardToColumn(node, column) {
      const { cache } = this.$apollo.getClient();
      addWorkItemToColumn({
        cache,
        query: this.columnQuery,
        variables: this.columnVariables(column),
        workItem: node,
        index: 0,
      });
      adjustWorkItemCountInColumn({
        cache,
        query: getWorkItemsCountOnlyQuery,
        variables: this.columnCountVariables(column),
        delta: 1,
      });
    },
    onDragStart(workItem) {
      this.invalidValueIds = this.groupValues
        .filter((value) => !this.isDropAllowed({ item: workItem, value }))
        .map((value) => value.id);
    },
    moveColumn(oldIndex, newIndex, reorderLabel) {
      if (
        oldIndex == null ||
        newIndex == null ||
        oldIndex === newIndex ||
        newIndex < 0 ||
        newIndex >= this.renderedColumns.length
      ) {
        return;
      }

      this.trackEvent('configure_columns_on_work_item_board', { label: reorderLabel });

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
      this.moveColumn(oldIndex, newIndex, 'reorder_drag');
    },
    // `delta` is how many positions to shift by: -1 for left, +1 for right.
    // moveColumn ignores an out-of-range target, so this is safe on edge columns.
    onColumnShift({ value, delta }) {
      const oldIndex = this.renderedColumns.findIndex((column) => column.id === value.id);
      if (oldIndex === -1) {
        return;
      }
      this.moveColumn(oldIndex, oldIndex + delta, 'reorder_menu');
    },
    async onColumnHide(value) {
      const visibleGroups = toggleGroupVisibility({
        visibleGroups: this.workItemsGroupByVisibleGroups,
        groupBy: this.groupBy,
        value,
        allGroups: this.groupValues,
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

      this.trackEvent('configure_columns_on_work_item_board', { label: 'hide_group' });

      this.$emit('hide-group', visibleGroups);
    },
    isDropAllowed({ item, value }) {
      return this.strategy?.isDropAllowed?.({ item, value, gateData: this.gateData }) ?? true;
    },
    async onCardMove({ from, to, item, oldIndex, newIndex }) {
      this.invalidValueIds = [];
      const fromValueId = from?.dataset?.columnValueId;
      const toValueId = to?.dataset?.columnValueId;
      const workItemId = item?.dataset?.workItemId;

      if (!fromValueId || !toValueId || !workItemId) {
        return;
      }

      const fromValue = this.valueById(fromValueId);
      const toValue = this.valueById(toValueId);
      if (!fromValue || !toValue) {
        return;
      }

      const valueChanged = fromValueId !== toValueId;

      const { cache } = this.$apollo.getClient();
      const query = this.columnQuery;
      const fromVariables = this.columnVariables(fromValue);
      const toVariables = this.columnVariables(toValue);

      // We read the target column's order before the move so the before/after
      // ids line up with where the card actually lands. Only relevant under
      // Manual sort — other sorts don't let you persist a position.
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

      if (!valueChanged && !moveBeforeId && !moveAfterId) {
        return;
      }

      // Snapshot the card now so the cache update below can reinsert it into the
      // target column on both the optimistic pass and the confirmed one.
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

      const moveKind = valueChanged ? 'column' : 'position';

      this.moveInProgress = true;
      const indicatorTimer = setTimeout(() => {
        this.showMoveInProgressIndicator = true;
      }, MOVE_IN_PROGRESS_INDICATOR_DELAY);
      try {
        // Apollo calls `update` twice: once straight away with our optimistic
        // response, then again once the server replies. If the mutation fails,
        // the optimistic change is rolled back and the card snaps back on its own.
        // We reinsert the `node` we snapshotted earlier (it has all the display
        // fields) rather than the id-only payload the mutation actually returns.
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

        this.trackEvent('move_card_on_work_item_board', { label: moveKind });

        if (valueChanged) {
          this.$toast.show(
            sprintf(I18N_MOVE_SUCCESS, { reference: node.reference, targetGroup: toValue.name }),
          );
        }
      } catch (error) {
        this.trackEvent('fail_card_move_on_work_item_board', { label: moveKind });
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
    <gl-loading-icon v-if="isLoading && groupValues.length === 0" size="lg" class="gl-m-auto" />
    <gl-empty-state
      v-else-if="needsGroupSelection"
      class="gl-m-auto"
      :title="$options.i18n.groupSelectionTitle"
      :description="groupSelectionPromptDescription"
      data-testid="group-selection-prompt"
    >
      <template #actions>
        <gl-button variant="confirm" @click="$emit('open-group-by-settings')">
          {{ $options.i18n.chooseGroups }}
        </gl-button>
      </template>
    </gl-empty-state>
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
      <board-column
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
      :confidential="inheritedConfidential"
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
