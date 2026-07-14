<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { RELATIVE_POSITION_ASC } from '~/work_items/list/constants';

import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import updateBoardWorkItemMutation from './graphql/update_board_work_item.mutation.graphql';
import { groupingStrategyFor } from './grouping';
import {
  boardColumnQuery,
  boardColumnQueryVariables,
  boardColumnCountVariables,
  getGroupId,
  getMovePositionIds,
} from './utils';
import {
  addWorkItemToColumn,
  adjustWorkItemCountInColumn,
  readWorkItemFromColumn,
  readWorkItemsFromColumn,
  removeWorkItemFromColumn,
} from './graphql/cache_updates';
import { I18N_MOVE_ERROR } from './constants';
import ColumnGroup from './components/column_group.vue';

export default {
  name: 'BoardView',
  components: {
    GlLoadingIcon,
    ColumnGroup,
  },
  mixins: [glFeatureFlagMixin()],
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
    // null means every group is visible; otherwise it holds the ids of the
    // groups to render. Not typed Array so a null default doesn't warn.
    visibleGroups: {
      required: false,
      default: null,
      validator: (value) => value === null || Array.isArray(value),
    },
  },
  emits: ['set-error', 'set-active-item', 'toggle-collapse'],
  data() {
    return {
      groupBy: { property: 'status' },
      groupByValues: [],
      gateData: null,
      // Column value ids the in-flight dragged item may not be dropped into.
      invalidValueIds: [],
      // Locks dragging while a move mutation is in flight so a second drop can't
      // compute before/after ids against a stale, not-yet-persisted order.
      moveInProgress: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.groupByValues.loading;
    },
    strategy() {
      return groupingStrategyFor(this.groupBy.property);
    },
    columnQuery() {
      return boardColumnQuery(this.glFeatures);
    },
    // Relative position is only meaningful under Manual sort; any other sort would
    // immediately override a reorder, so we don't persist position then.
    isManualSort() {
      return this.queryVariables.sort === RELATIVE_POSITION_ASC;
    },
    // Columns hidden via display settings are removed from the board entirely.
    visibleGroupByValues() {
      if (this.visibleGroups === null) {
        return this.groupByValues;
      }
      return this.groupByValues.filter((value) => this.visibleGroups.includes(this.groupId(value)));
    },
  },
  apollo: {
    groupByValues() {
      return {
        query: this.strategy?.valuesQuery,
        skip() {
          return !this.strategy;
        },
        variables() {
          return { fullPath: this.rootPageFullPath };
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
        groupProperty: this.groupBy.property,
        value,
      });
    },
    onDragStart(workItem) {
      this.invalidValueIds = this.groupByValues
        .filter((value) => !this.isDropAllowed({ item: workItem, value }))
        .map((value) => value.id);
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
            nodes: readWorkItemsFromColumn({ cache, query, variables: toVariables }),
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
      const node = readWorkItemFromColumn({ cache, query, variables: fromVariables, workItemId });
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

            removeWorkItemFromColumn({ cache: store, query, variables: fromVariables, workItemId });
            addWorkItemToColumn({
              cache: store,
              query,
              variables: toVariables,
              workItem: node,
              index: newIndex,
              // Only patch the card on a cross-column move; a reorder keeps its value.
              patchCard: valueChanged
                ? (draftNode) => this.strategy.patchCard(draftNode, toValue)
                : null,
            });

            // The header counts live in their own count-only query cache, so keep them
            // in step with the connection updates above (rolled back on a failed move).
            adjustWorkItemCountInColumn({
              cache: store,
              query: getWorkItemsCountOnlyQuery,
              variables: this.columnCountVariables(fromValue),
              delta: -1,
            });
            adjustWorkItemCountInColumn({
              cache: store,
              query: getWorkItemsCountOnlyQuery,
              variables: this.columnCountVariables(toValue),
              delta: 1,
            });
          },
        });

        if (data?.workItemUpdate?.errors?.length) {
          throw new Error(data.workItemUpdate.errors.join(', '));
        }
      } catch (error) {
        this.$toast.show(I18N_MOVE_ERROR);
        Sentry.captureException(error);
      } finally {
        this.moveInProgress = false;
      }
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-w-full gl-gap-3 gl-overflow-x-auto gl-py-5"
    style="height: calc(100dvh - 220px - 2rem)"
  >
    <gl-loading-icon v-if="isLoading && groupByValues.length === 0" size="lg" class="gl-m-auto" />
    <column-group
      v-for="value in visibleGroupByValues"
      :key="value.id"
      :value="value"
      :strategy="strategy"
      :root-page-full-path="rootPageFullPath"
      :base-query-variables="queryVariables"
      :drag-disabled="moveInProgress"
      :drop-disabled="invalidValueIds.includes(value.id)"
      :collapsed="isColumnCollapsed(value)"
      :hidden-metadata-keys="hiddenMetadataKeys"
      :active-item="activeItem"
      :detail-panel-enabled="detailPanelEnabled"
      @drag-start="onDragStart"
      @card-move="onCardMove"
      @set-active-item="$emit('set-active-item', $event)"
      @toggle-collapse="$emit('toggle-collapse', groupId(value))"
    />
  </div>
</template>
