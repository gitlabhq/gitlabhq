<script>
import Draggable from 'vuedraggable';
import { cloneDeep } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { isLoggedIn } from '~/lib/utils/common_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import { defaultSortableOptions, DRAG_DELAY } from '~/sortable/constants';

import { WORK_ITEM_TYPE_VALUE_OBJECTIVE, WORK_ITEM_TYPE_VALUE_EPIC } from '../../constants';
import { findHierarchyWidgets, findHierarchyWidgetChildren } from '../../utils';
import {
  addHierarchyChild,
  removeHierarchyChild,
  optimisticUserPermissions,
} from '../../graphql/cache_utils';
import toggleHierarchyTreeChildMutation from '../../graphql/client/toggle_hierarchy_tree_child.mutation.graphql';
import moveWorkItem from '../../graphql/move_work_item.mutation.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import getWorkItemTreeQuery from '../../graphql/work_item_tree.query.graphql';
import WorkItemLinkChild from './work_item_link_child.vue';

export default {
  components: {
    WorkItemLinkChild,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    children: {
      type: Array,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    showLabels: {
      type: Boolean,
      required: false,
      default: true,
    },
    disableContent: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowedChildTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
    isTopLevel: {
      type: Boolean,
      required: false,
      default: true,
    },
    parent: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      prefetchedWorkItem: null,
      updateInProgress: false,
      currentClientX: 0,
      currentClientY: 0,
      childrenWorkItems: [],
      toParent: {},
    };
  },
  computed: {
    canReorder() {
      return isLoggedIn() && this.canUpdate;
    },
    treeRootWrapper() {
      return this.canReorder ? Draggable : 'ul';
    },
    treeRootOptions() {
      const options = {
        ...defaultSortableOptions,
        fallbackOnBody: false,
        group: 'sortable-container',
        tag: 'ul',
        'data-parent-id': this.workItemId,
        'data-parent-title': this.parent.title,
        value: this.children,
        delay: DRAG_DELAY,
        delayOnTouchOnly: true,
      };

      return this.canReorder ? options : {};
    },
    hasIndirectChildren() {
      return this.children
        .map((child) => findHierarchyWidgets(child.widgets) || {})
        .some((hierarchy) => hierarchy.hasChildren);
    },
    disableList() {
      return this.disableContent || this.updateInProgress;
    },
    apolloClient() {
      return this.$apollo.provider.clients.defaultClient;
    },
  },
  methods: {
    async removeChild(child) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: { input: { id: child.id, hierarchyWidget: { parentId: null } } },
          update: (cache) =>
            removeHierarchyChild({
              cache,
              id: this.workItemId,
              workItem: child,
            }),
        });

        if (data.workItemUpdate.errors.length) {
          throw new Error(data.workItemUpdate.errors);
        }

        this.$toast.show(s__('WorkItem|Child removed'), {
          action: {
            text: s__('WorkItem|Undo'),
            onClick: (_, toast) => {
              this.undoChildRemoval(child);
              toast.hide();
            },
          },
        });
      } catch (error) {
        this.$emit('error', s__('WorkItem|Something went wrong while removing child.'));
        Sentry.captureException(error);
      }
    },
    async undoChildRemoval(child) {
      try {
        this.updateInProgress = true;
        const { data } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: { input: { id: child.id, hierarchyWidget: { parentId: this.workItemId } } },
          update: (cache) =>
            addHierarchyChild({
              cache,
              id: this.workItemId,
              workItem: child,
            }),
        });

        if (data.workItemUpdate.errors.length) {
          throw new Error(data.workItemUpdate.errors);
        }

        this.$toast.show(s__('WorkItem|Child removal reverted'));
      } catch (error) {
        this.$emit('error', s__('WorkItem|Something went wrong while undoing child removal.'));
        Sentry.captureException(error);
      } finally {
        this.updateInProgress = false;
      }
    },
    addWorkItemQuery({ iid }) {
      this.$apollo.addSmartQuery('prefetchedWorkItem', {
        query: workItemByIidQuery,
        variables: {
          fullPath: this.fullPath,
          iid,
        },
        update(data) {
          return data.workspace.workItem;
        },
      });
    },
    prefetchWorkItem({ iid }) {
      if (this.workItemType !== WORK_ITEM_TYPE_VALUE_OBJECTIVE) {
        this.prefetch = setTimeout(
          () => this.addWorkItemQuery({ iid }),
          DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
        );
      }
    },
    clearPrefetching() {
      if (this.prefetch) {
        clearTimeout(this.prefetch);
      }
    },
    async fetchChildren(id) {
      await this.$apollo.addSmartQuery('childrenWorkItems', {
        query: getWorkItemTreeQuery,
        variables: {
          id,
        },
        update: (data) => findHierarchyWidgetChildren(data?.workItem),
        result({ data }) {
          const { workItem } = data;
          this.toParent = {
            id: workItem.id,
            title: workItem.title,
            confidential: workItem.confidential,
            workItemType: workItem.workItemType,
          };
        },
        error() {
          this.$emit('error', s__('Hierarchy|Something went wrong while fetching children.'));
        },
      });
    },

    getReorderParams({ oldIndex, newIndex }) {
      let relativePosition;

      // adjacentWorkItemId is always the item that's at the position
      // where target was moved.
      const adjacentWorkItemId = this.children[newIndex].id;

      if (newIndex === 0) {
        // If newIndex is `0`, item was moved to the top.
        // Adjacent reference will be the one which is currently at the top,
        // and it's relative position with respect to target's new position is `BEFORE`.
        relativePosition = 'BEFORE';
      } else if (newIndex === this.children.length - 1) {
        // If newIndex is last position in list, item was moved to the bottom.
        // Adjacent reference will be the one which is currently at the bottom,
        // and it's relative position with respect to target's new position is `AFTER`.
        relativePosition = 'AFTER';
      } else if (oldIndex < newIndex) {
        // If newIndex is neither top nor bottom, it was moved somewhere in the middle.
        // Adjacent reference will be the one which is currently at that position,

        // when the item is moved down, the newIndex is after the adjacent reference.
        relativePosition = 'AFTER';
      } else {
        // when the item is moved up, the newIndex is before the adjacent reference.
        relativePosition = 'BEFORE';
      }

      return {
        relativePosition,
        adjacentWorkItemId,
      };
    },
    async getMoveItemParams({ toParentId, newIndex }) {
      await this.fetchChildren(toParentId);
      let adjacentWorkItemId;
      let relativePosition;
      if (this.childrenWorkItems.length > 0) {
        relativePosition = 'BEFORE';
        adjacentWorkItemId = this.childrenWorkItems[newIndex]?.id;
        if (!adjacentWorkItemId) {
          adjacentWorkItemId = this.childrenWorkItems[this.childrenWorkItems.length - 1].id;
          relativePosition = 'AFTER';
        }
      }
      return {
        adjacentWorkItemId,
        relativePosition,
        parentId: toParentId,
      };
    },
    async handleDragOnEnd(params) {
      clearTimeout(this.toggleTimer);
      const { oldIndex, newIndex, from, to } = params;
      const fromParentId = from.dataset.parentId;
      const toParentId = to.dataset.parentId;
      const toParentTitle = to.dataset.parentTitle;
      const targetItem = this.children[oldIndex];
      let hierarchyWidgetParams;
      let updatedChildren;
      let toParentHasChildren;

      this.updateInProgress = true;
      if (fromParentId === toParentId) {
        if (oldIndex === newIndex) {
          this.updateInProgress = false;
          return;
        }
        hierarchyWidgetParams = this.getReorderParams({ oldIndex, newIndex });
        updatedChildren = cloneDeep(this.children);
        updatedChildren.splice(oldIndex, 1);
      } else {
        hierarchyWidgetParams = await this.getMoveItemParams({ toParentId, newIndex });
        updatedChildren = cloneDeep(this.childrenWorkItems);
        toParentHasChildren = updatedChildren.length > 0;
      }

      updatedChildren.splice(newIndex, 0, targetItem);
      const currentPageSize = updatedChildren.length;

      this.$apollo
        .mutate({
          mutation: moveWorkItem,
          variables: {
            pageSize: currentPageSize,
            endCursor: '',
            input: {
              id: targetItem.id,
              ...hierarchyWidgetParams,
            },
          },
          update: async (cache) => {
            if (fromParentId !== toParentId) {
              removeHierarchyChild({
                cache,
                id: fromParentId,
                workItem: targetItem,
              });
              // When the new parent does not have existing children, it needs to be expanded
              if (!toParentHasChildren) {
                this.openChild(toParentId);
              }
            }
          },
          optimisticResponse: {
            workItemsHierarchyReorder: {
              __typename: 'workItemsHierarchyReorderPayload',
              workItem: {
                ...targetItem,
                userPermissions: optimisticUserPermissions,
                widgets: [
                  {
                    __typename: 'WorkItemWidgetHierarchy',
                    type: 'HIERARCHY',
                    hasChildren: false,
                    parent: { id: toParentId },
                    children: [],
                  },
                ],
              },
              parentWorkItem: {
                __typename: 'WorkItem',
                id: toParentId,
                userPermissions: optimisticUserPermissions,
                confidential: this.toParent.confidential || this.parent.confidential,
                title: toParentTitle,
                workItemType: this.toParent.workItemType || this.parent.workItemType,
                widgets: [
                  {
                    __typename: 'WorkItemWidgetHierarchy',
                    type: 'HIERARCHY',
                    hasChildren: true,
                    parent: null,
                    children: {
                      __typename: 'WorkItemConnection',
                      pageInfo: {
                        hasNextPage: false,
                        hasPreviousPage: false,
                        startCursor: '',
                        endCursor: '',
                      },
                      count: updatedChildren.length,
                      nodes: [...updatedChildren],
                    },
                  },
                ],
              },
              errors: [],
            },
          },
        })
        .then(
          ({
            data: {
              workItemsHierarchyReorder: { errors },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }
          },
        )
        .catch((error) => {
          this.$emit('error', error.message);
          Sentry.captureException(error);
          if (fromParentId !== toParentId) {
            const { cache } = this.apolloClient;
            addHierarchyChild({
              cache,
              id: fromParentId,
              workItem: targetItem,
              atIndex: oldIndex,
            });
          }
        })
        .finally(() => {
          this.updateInProgress = false;
        });
    },
    onMove(e, originalEvent) {
      const item = e.relatedContext.element;
      const { clientX, clientY } = originalEvent;

      // Cache current cursor position
      this.currentClientX = clientX;
      this.currentClientY = clientY;

      // Check if current item is an Epic
      if (
        [WORK_ITEM_TYPE_VALUE_EPIC, WORK_ITEM_TYPE_VALUE_OBJECTIVE].includes(
          item?.workItemType.name,
        )
      ) {
        const { top, left } = originalEvent.target.getBoundingClientRect();

        // Check if user has paused cursor on top of current item's boundary
        if (clientY >= top && clientX >= left) {
          // Wait for moment before expanding
          this.toggleTimer = setTimeout(() => {
            // Ensure that current cursor position is still within item's boundary
            if (this.currentClientX === clientX && this.currentClientY === clientY) {
              this.openChild(item.id);
            }
          }, 1000);
        } else {
          clearTimeout(this.toggleTimer);
        }
      }
    },
    onClick(event, child) {
      if (this.isTopLevel) {
        this.$emit('show-modal', { event, child: event.childItem || child });
      } else {
        // To avoid incorrect work item to be bubbled up
        // Assign the correct child item
        if (!event.childItem) {
          Object.assign(event, { childItem: child });
        }
        this.$emit('click', event);
      }
    },
    openChild(id) {
      this.$apollo.mutate({
        mutation: toggleHierarchyTreeChildMutation,
        variables: {
          id,
          isExpanded: true,
        },
      });
    },
  },
};
</script>

<template>
  <component
    :is="treeRootWrapper"
    v-bind="treeRootOptions"
    class="content-list"
    data-testid="child-items-container"
    :class="{ 'sortable-container gl-cursor-grab': canReorder, 'disabled-content': disableList }"
    :move="onMove"
    @end="handleDragOnEnd"
  >
    <work-item-link-child
      v-for="child in children"
      :key="child.id"
      :can-update="canUpdate"
      :issuable-gid="child.id"
      :child-item="child"
      :confidential="child.confidential"
      :work-item-type="child.workItemType.name"
      :has-indirect-children="hasIndirectChildren"
      :show-labels="showLabels"
      :work-item-full-path="fullPath"
      :allowed-child-types="allowedChildTypes"
      :is-top-level="isTopLevel"
      :data-child-title="child.title"
      @mouseover="prefetchWorkItem(child)"
      @mouseout="clearPrefetching"
      @removeChild="removeChild"
      @error="$emit('error', $event)"
      @click="onClick($event, child)"
    />
  </component>
</template>
