<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { STATE_OPEN, WORK_ITEM_TYPE_VALUE_TASK } from '../../constants';
import { findHierarchyWidgets, getDefaultHierarchyChildrenCount, getItems } from '../../utils';
import toggleHierarchyTreeChildMutation from '../../graphql/client/toggle_hierarchy_tree_child.mutation.graphql';
import isExpandedHierarchyTreeChildQuery from '../../graphql/client/is_expanded_hierarchy_tree_child.query.graphql';
import getWorkItemTreeQuery from '../../graphql/work_item_tree.query.graphql';
import WorkItemLinkChildContents from '../shared/work_item_link_child_contents.vue';
import WorkItemChildrenLoadMore from '../shared/work_item_children_load_more.vue';

export default {
  name: 'WorkItemLinkChild',
  components: {
    GlButton,
    WorkItemChildrenWrapper: () => import('./work_item_children_wrapper.vue'),
    WorkItemLinkChildContents,
    WorkItemChildrenLoadMore,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    canUpdate: {
      type: Boolean,
      required: true,
    },
    issuableGid: {
      type: String,
      required: true,
    },
    childItem: {
      type: Object,
      required: true,
    },
    hasIndirectChildren: {
      type: Boolean,
      required: false,
      default: true,
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
    showLabels: {
      type: Boolean,
      required: false,
      default: true,
    },
    showClosed: {
      type: Boolean,
      required: false,
      default: true,
    },
    workItemFullPath: {
      type: String,
      required: false,
      default: '',
    },
    isTopLevel: {
      type: Boolean,
      required: false,
      default: false,
    },
    draggedItemType: {
      type: String,
      required: false,
      default: null,
    },
    showTaskWeight: {
      type: Boolean,
      required: false,
      default: true,
    },
    allowedChildrenByType: {
      type: Object,
      required: false,
      default: () => {},
    },
    activeChildItemId: {
      type: String,
      required: false,
      default: null,
    },
    parentId: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isExpanded: false,
      isLoadingChildren: false,
      children: [],
      fetchNextPageInProgress: false,
      hierarchyWidget: {},
      childItemId: '',
    };
  },
  apollo: {
    hierarchyWidget: {
      query: getWorkItemTreeQuery,
      variables() {
        return {
          id: this.childItemId,
          pageSize: getDefaultHierarchyChildrenCount(),
          endCursor: '',
        };
      },
      skip() {
        return !this.childItemId;
      },
      update({ workItem }) {
        if (workItem) {
          this.isLoadingChildren = false;
          const { hasChildren, children } = findHierarchyWidgets(workItem.widgets);
          this.children = children.nodes;
          return {
            pageInfo: children.pageInfo,
            count: children.count,
            nodes: children.nodes,
            hasChildren,
          };
        }
        this.childItemId = '';
        return {};
      },
      error(error) {
        createAlert({
          message: s__('Hierarchy|Something went wrong while fetching children.'),
          captureError: true,
          error,
        });
      },
      result() {
        if (this.hasNextPage && this.children.length === 0) {
          this.fetchNextPage();
        }
      },
    },
    isExpanded: {
      query: isExpandedHierarchyTreeChildQuery,
      variables() {
        return { id: this.childItem.id };
      },
      update(data) {
        this.childItemId = data?.isExpandedHierarchyTreeChild?.id;
        return data?.isExpandedHierarchyTreeChild?.isExpanded || false;
      },
    },
  },
  computed: {
    hasChildren() {
      return (
        findHierarchyWidgets(this.childItem.widgets).hasChildren ||
        this.hierarchyWidget?.hasChildren
      );
    },
    shouldExpandChildren() {
      // In case the parent is the same as the child,
      // it is creating a cycle and recursively expanding the tree
      // Issue details: https://gitlab.com/gitlab-org/gitlab/-/issues/498106
      if (this.parentId === this.childItem.id) {
        return false;
      }
      const rolledUpCountsByType =
        findHierarchyWidgets(this.childItem.widgets)?.rolledUpCountsByType || [];
      const nrOpenChildren = rolledUpCountsByType
        .map((i) => i.countsByState.all - i.countsByState.closed)
        .reduce((sum, n) => sum + n, 0);

      return this.hasChildren && (nrOpenChildren > 0 || this.showClosed);
    },
    pageInfo() {
      return this.hierarchyWidget.pageInfo || {};
    },
    hasNextPage() {
      return Boolean(this.pageInfo?.hasNextPage);
    },
    endCursor() {
      return this.pageInfo?.endCursor || '';
    },
    isItemOpen() {
      return this.childItem.state === STATE_OPEN;
    },
    childItemType() {
      return this.childItem.workItemType.name;
    },
    iconClass() {
      if (this.childItemType === WORK_ITEM_TYPE_VALUE_TASK) {
        return this.isItemOpen ? 'gl-fill-icon-success' : 'gl-fill-icon-info';
      }
      return '';
    },
    stateTimestamp() {
      return this.isItemOpen ? this.childItem.createdAt : this.childItem.closedAt;
    },
    stateTimestampTypeText() {
      return this.isItemOpen ? __('Created') : __('Closed');
    },
    chevronType() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
    chevronTooltip() {
      return this.isExpanded ? __('Collapse') : __('Expand');
    },
    childItemClass() {
      return {
        '!gl-ml-0': this.hasChildren || (!this.hasIndirectChildren && this.isTopLevel),
        'gl-bg-blue-50 hover:gl-bg-blue-50 gl-border-default': this.isActive,
      };
    },
    shouldShowWeight() {
      return this.childItemType === WORK_ITEM_TYPE_VALUE_TASK ? this.showTaskWeight : true;
    },
    allowedChildTypes() {
      return this.allowedChildrenByType?.[this.childItemType] || [];
    },
    draggedItemTypeIsAllowed() {
      return this.allowedChildTypes.includes(this.draggedItemType);
    },
    showChildrenDropzone() {
      return !this.hasChildren && this.draggedItemTypeIsAllowed;
    },
    displayableChildren() {
      const filterClosed = getItems(this.showClosed);
      return filterClosed(this.children);
    },
    isActive() {
      return this.activeChildItemId === this.childItem.id;
    },
  },
  methods: {
    toggleItem() {
      if (this.children.length === 0 && this.hasChildren) {
        this.isLoadingChildren = true;
        this.childItemId = this.childItem.id;
      }
      this.$apollo.mutate({
        mutation: toggleHierarchyTreeChildMutation,
        variables: {
          id: this.childItem.id,
          isExpanded: !this.isExpanded,
        },
      });
    },
    async fetchNextPage() {
      if (this.hasNextPage && !this.fetchNextPageInProgress) {
        this.fetchNextPageInProgress = true;

        try {
          await this.$apollo.queries.hierarchyWidget.fetchMore({
            variables: {
              endCursor: this.endCursor,
            },
          });
        } catch (error) {
          createAlert({
            message: s__('Hierarchy|Something went wrong while fetching children.'),
            captureError: true,
            error,
          });
        } finally {
          this.fetchNextPageInProgress = false;
        }
      }
    },
  },
};
</script>

<template>
  <li class="tree-item !gl-px-0 !gl-py-2">
    <div class="gl-flex gl-items-start">
      <div v-if="hasIndirectChildren" class="gl-mr-2 gl-h-7 gl-w-5">
        <gl-button
          v-if="shouldExpandChildren"
          v-gl-tooltip.hover
          :title="chevronTooltip"
          :aria-label="chevronTooltip"
          :icon="chevronType"
          category="tertiary"
          size="small"
          :loading="isLoadingChildren && !fetchNextPageInProgress"
          class="!gl-px-0 !gl-py-3"
          data-testid="expand-child"
          @click.stop="toggleItem"
        />
      </div>
      <div
        data-testid="child-contents-container"
        class="gl-w-full"
        :class="{
          '!gl-border-x-0 !gl-border-b-1 !gl-border-t-0 !gl-border-solid gl-border-default !gl-pb-2':
            isExpanded && shouldExpandChildren && !isLoadingChildren,
        }"
      >
        <work-item-link-child-contents
          :child-item="childItem"
          :can-update="canUpdate"
          :class="childItemClass"
          :parent-work-item-id="issuableGid"
          :work-item-type="workItemType"
          :show-labels="showLabels"
          :show-closed="showClosed"
          :work-item-full-path="workItemFullPath"
          :show-weight="shouldShowWeight"
          :is-active="isActive"
          @click="$emit('click', $event)"
          @removeChild="$emit('removeChild', childItem)"
        />
      </div>
    </div>
    <div class="!gl-ml-6">
      <work-item-children-wrapper
        v-if="isExpanded || showChildrenDropzone"
        :can-update="canUpdate"
        :work-item-id="issuableGid"
        :work-item-iid="childItem.iid"
        :work-item-type="workItemType"
        :children="displayableChildren"
        :parent="childItem"
        :show-labels="showLabels"
        :show-closed="showClosed"
        :full-path="workItemFullPath"
        :is-top-level="false"
        :show-task-weight="showTaskWeight"
        :has-indirect-children="hasIndirectChildren"
        :dragged-item-type="draggedItemType"
        :allowed-children-by-type="allowedChildrenByType"
        :active-child-item-id="activeChildItemId"
        :parent-id="parentId"
        @drag="$emit('drag', $event)"
        @drop="$emit('drop')"
        @removeChild="$emit('removeChild', childItem)"
        @error="$emit('error', $event)"
        @click="$emit('click', $event)"
      />
      <work-item-children-load-more
        v-if="hasNextPage && isExpanded"
        class="!gl-pl-5"
        data-testid="work-item-load-more"
        :fetch-next-page-in-progress="fetchNextPageInProgress"
        @fetch-next-page="fetchNextPage"
      />
    </div>
  </li>
</template>
