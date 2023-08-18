<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import * as Sentry from '@sentry/browser';
import { __, s__ } from '~/locale';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import {
  STATE_OPEN,
  TASK_TYPE_NAME,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_NAME_TO_ICON_MAP,
} from '../../constants';
import getWorkItemTreeQuery from '../../graphql/work_item_tree.query.graphql';
import WorkItemLinkChildContents from '../shared/work_item_link_child_contents.vue';
import WorkItemTreeChildren from './work_item_tree_children.vue';

export default {
  components: {
    GlButton,
    WorkItemTreeChildren,
    WorkItemLinkChildContents,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['fullPath'],
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
  },
  data() {
    return {
      isExpanded: false,
      children: [],
      isLoadingChildren: false,
      activeToast: null,
      childrenBeforeRemoval: [],
      hasChildren: false,
    };
  },
  computed: {
    canHaveChildren() {
      return this.workItemType === WORK_ITEM_TYPE_VALUE_OBJECTIVE;
    },
    isItemOpen() {
      return this.childItem.state === STATE_OPEN;
    },
    childItemType() {
      return this.childItem.workItemType.name;
    },
    iconName() {
      if (this.childItemType === TASK_TYPE_NAME) {
        return this.isItemOpen ? 'issue-open-m' : 'issue-close';
      }
      return WORK_ITEM_NAME_TO_ICON_MAP[this.childItemType];
    },
    iconClass() {
      if (this.childItemType === TASK_TYPE_NAME) {
        return this.isItemOpen ? 'gl-text-green-500' : 'gl-text-blue-500';
      }
      return '';
    },
    stateTimestamp() {
      return this.isItemOpen ? this.childItem.createdAt : this.childItem.closedAt;
    },
    stateTimestampTypeText() {
      return this.isItemOpen ? __('Created') : __('Closed');
    },
    childPath() {
      return `${gon?.relative_url_root || ''}/${this.fullPath}/-/work_items/${this.childItem.iid}`;
    },
    chevronType() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
    chevronTooltip() {
      return this.isExpanded ? __('Collapse') : __('Expand');
    },
  },
  watch: {
    childItem: {
      handler(val) {
        this.hasChildren = this.getWidgetByType(val, WIDGET_TYPE_HIERARCHY)?.hasChildren;
      },
      immediate: true,
    },
    children(val) {
      this.hasChildren = val?.length > 0;
    },
  },
  methods: {
    toggleItem() {
      this.isExpanded = !this.isExpanded;
      if (this.children.length === 0 && this.hasChildren) {
        this.fetchChildren();
      }
    },
    getWidgetByType(workItem, widgetType) {
      return workItem?.widgets?.find((widget) => widget.type === widgetType);
    },
    async fetchChildren() {
      this.isLoadingChildren = true;
      try {
        const { data } = await this.$apollo.query({
          query: getWorkItemTreeQuery,
          variables: {
            id: this.childItem.id,
          },
        });
        this.children = this.getWidgetByType(data?.workItem, WIDGET_TYPE_HIERARCHY).children.nodes;
      } catch (error) {
        this.isExpanded = !this.isExpanded;
        createAlert({
          message: s__('Hierarchy|Something went wrong while fetching children.'),
          captureError: true,
          error,
        });
      } finally {
        this.isLoadingChildren = false;
      }
    },
    showScopedLabel(label) {
      return isScopedLabel(label) && this.allowsScopedLabels;
    },
    async removeChild({ id }) {
      this.cloneChildren();
      this.isLoadingChildren = true;

      try {
        const { data } = await this.updateWorkItem(id, null);
        if (!data?.workItemUpdate?.errors?.length) {
          this.filterRemovedChild(id);

          this.activeToast = this.$toast.show(s__('WorkItem|Child removed'), {
            action: {
              text: s__('WorkItem|Undo'),
              onClick: this.undoChildRemoval.bind(this, id),
            },
          });
        }
      } catch (error) {
        this.showAlert(s__('WorkItem|Something went wrong while removing child.'), error);
        Sentry.captureException(error);
        this.restoreChildren();
      } finally {
        this.isLoadingChildren = false;
      }
    },
    async undoChildRemoval(childId) {
      this.isLoadingChildren = true;
      try {
        const { data } = await this.updateWorkItem(childId, this.childItem.id);
        if (!data?.workItemUpdate?.errors?.length) {
          this.activeToast?.hide();
          this.restoreChildren();
        }
      } catch (error) {
        this.showAlert(s__('WorkItem|Something went wrong while undoing child removal.'), error);
        Sentry.captureException(error);
      } finally {
        this.activeToast?.hide();
        this.childrenBeforeRemoval = [];
        this.isLoadingChildren = false;
      }
    },
    async updateWorkItem(childId, parentId) {
      return this.$apollo.mutate({
        mutation: updateWorkItemMutation,
        variables: { input: { id: childId, hierarchyWidget: { parentId } } },
      });
    },
    cloneChildren() {
      this.childrenBeforeRemoval = cloneDeep(this.children);
    },
    filterRemovedChild(childId) {
      this.children = this.children.filter(({ id }) => id !== childId);
    },
    restoreChildren() {
      this.children = [...this.childrenBeforeRemoval];
    },
    showAlert(message, error) {
      createAlert({
        message,
        captureError: true,
        error,
      });
    },
  },
};
</script>

<template>
  <div class="tree-item">
    <div
      class="gl-display-flex gl-align-items-flex-start"
      :class="{ 'gl-ml-6': canHaveChildren && !hasChildren && hasIndirectChildren }"
    >
      <gl-button
        v-if="hasChildren"
        v-gl-tooltip.hover
        :title="chevronTooltip"
        :aria-label="chevronTooltip"
        :icon="chevronType"
        category="tertiary"
        size="small"
        :loading="isLoadingChildren"
        class="gl-px-0! gl-py-3! gl-mr-3"
        data-testid="expand-child"
        @click="toggleItem"
      />
      <work-item-link-child-contents
        :child-item="childItem"
        :can-update="canUpdate"
        :parent-work-item-id="issuableGid"
        :work-item-type="workItemType"
        :child-path="childPath"
        @click="$emit('click', $event)"
        @removeChild="$emit('removeChild', childItem)"
      />
    </div>
    <work-item-tree-children
      v-if="isExpanded"
      :can-update="canUpdate"
      :work-item-id="issuableGid"
      :work-item-type="workItemType"
      :children="children"
      @removeChild="removeChild"
      @click="$emit('click', $event)"
    />
  </div>
</template>
