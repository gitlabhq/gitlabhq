<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import { createAlert } from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RichTimestampTooltip from '~/vue_shared/components/rich_timestamp_tooltip.vue';

import {
  STATE_OPEN,
  TASK_TYPE_NAME,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_NAME_TO_ICON_MAP,
} from '../../constants';
import getWorkItemTreeQuery from '../../graphql/work_item_tree.query.graphql';
import WorkItemLinksMenu from './work_item_links_menu.vue';
import WorkItemTreeChildren from './work_item_tree_children.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    RichTimestampTooltip,
    WorkItemLinksMenu,
    WorkItemTreeChildren,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
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
      return `/${this.projectPath}/-/work_items/${getIdFromGraphQLId(this.childItem.id)}`;
    },
    hasChildren() {
      return this.getWidgetHierarchyForChild(this.childItem)?.hasChildren;
    },
    chevronType() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
    chevronTooltip() {
      return this.isExpanded ? __('Collapse') : __('Expand');
    },
  },
  methods: {
    toggleItem() {
      this.isExpanded = !this.isExpanded;
      if (this.children.length === 0 && this.hasChildren) {
        this.fetchChildren();
      }
    },
    getWidgetHierarchyForChild(workItem) {
      const widgetHierarchy = workItem?.widgets?.find(
        (widget) => widget.type === WIDGET_TYPE_HIERARCHY,
      );
      return widgetHierarchy || {};
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
        this.children = this.getWidgetHierarchyForChild(data?.workItem).children.nodes;
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
  },
};
</script>

<template>
  <div>
    <div
      class="gl-display-flex gl-align-items-center gl-mb-3"
      :class="{ 'gl-ml-6': canHaveChildren && !hasChildren && hasIndirectChildren }"
    >
      <gl-button
        v-if="hasChildren"
        v-gl-tooltip.viewport
        :title="chevronTooltip"
        :aria-label="chevronTooltip"
        :icon="chevronType"
        category="tertiary"
        :loading="isLoadingChildren"
        class="gl-px-0! gl-py-4! gl-mr-3"
        data-testid="expand-child"
        @click="toggleItem"
      />
      <div
        class="gl-relative gl-display-flex gl-flex-grow-1 gl-overflow-break-word gl-min-w-0 gl-bg-white gl-py-3 gl-px-4 gl-border gl-border-gray-100 gl-rounded-base gl-line-height-32"
        data-testid="links-child"
      >
        <div class="gl-overflow-hidden gl-display-flex gl-align-items-center gl-flex-grow-1">
          <span :id="`stateIcon-${childItem.id}`" class="gl-mr-3" data-testid="item-status-icon">
            <gl-icon
              class="gl-text-secondary"
              :class="iconClass"
              :name="iconName"
              :aria-label="stateTimestampTypeText"
            />
          </span>
          <rich-timestamp-tooltip
            :target="`stateIcon-${childItem.id}`"
            :raw-timestamp="stateTimestamp"
            :timestamp-type-text="stateTimestampTypeText"
          />
          <gl-icon
            v-if="childItem.confidential"
            v-gl-tooltip.top
            name="eye-slash"
            class="gl-mr-2 gl-text-orange-500"
            data-testid="confidential-icon"
            :aria-label="__('Confidential')"
            :title="__('Confidential')"
          />
          <gl-button
            :href="childPath"
            category="tertiary"
            variant="link"
            class="gl-text-truncate gl-max-w-80 gl-text-black-normal!"
            @click="$emit('click', $event)"
            @mouseover="$emit('mouseover')"
            @mouseout="$emit('mouseout')"
          >
            {{ childItem.title }}
          </gl-button>
        </div>
        <div
          v-if="canUpdate"
          class="gl-ml-0 gl-sm-ml-auto! gl-display-inline-flex gl-align-items-center"
        >
          <work-item-links-menu
            :work-item-id="childItem.id"
            :parent-work-item-id="issuableGid"
            data-testid="links-menu"
            @removeChild="$emit('removeChild', childItem.id)"
          />
        </div>
      </div>
    </div>
    <work-item-tree-children
      v-if="isExpanded"
      :project-path="projectPath"
      :can-update="canUpdate"
      :work-item-id="issuableGid"
      :work-item-type="workItemType"
      :children="children"
      @removeChild="fetchChildren"
    />
  </div>
</template>
