<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { STATUS_CLOSED } from '~/issues/constants';
import { STATE_CLOSED, METADATA_KEYS } from '~/work_items/constants';
import {
  findMilestoneWidget,
  findStartAndDueDateWidget,
  findTimeTrackingWidget,
  findHierarchyWidget,
} from '~/work_items/utils';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';
import WorkItemDatesAttribute from '~/work_items/components/shared/work_item_dates_attribute.vue';
import WorkItemParentMetadata from '~/work_items/components/shared/work_item_parent_metadata.vue';

export default {
  name: 'IssueCardTimeInfo',
  components: {
    IssuableMilestone,
    WorkItemAttribute,
    WorkItemDatesAttribute,
    WorkItemParentMetadata,
    GlSkeletonLoader,
  },
  constants: {
    METADATA_KEYS,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    detailLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    hiddenMetadataKeys: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    milestone() {
      return (
        this.issue.milestone ||
        this.issue?.features?.milestone?.milestone ||
        findMilestoneWidget(this.issue)?.milestone
      );
    },
    dueDate() {
      return this.issue.dueDate || findStartAndDueDateWidget(this.issue)?.dueDate;
    },
    hasDates() {
      return Boolean(this.startDate || this.dueDate);
    },
    isClosed() {
      return this.issue.state === STATUS_CLOSED || this.issue.state === STATE_CLOSED;
    },
    startDate() {
      return findStartAndDueDateWidget(this.issue)?.startDate;
    },
    timeEstimate() {
      return (
        findTimeTrackingWidget(this.issue)?.humanReadableAttributes?.timeEstimate ||
        this.issue.humanTimeEstimate ||
        this.issue.timeStats?.humanTimeEstimate
      );
    },
    parent() {
      return findHierarchyWidget(this.issue)?.parent;
    },
  },
};
</script>

<template>
  <div class="gl-contents">
    <work-item-parent-metadata
      v-if="parent && !hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.PARENT)"
      :parent="parent"
      :icon-size="12"
    />
    <slot name="weight"></slot>
    <issuable-milestone
      v-if="milestone && !hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.MILESTONE)"
      :milestone="milestone"
    />
    <span v-else-if="detailLoading">
      <gl-skeleton-loader :width="55" :lines="1" equal-width-lines />
    </span>
    <slot name="iteration"></slot>
    <work-item-dates-attribute
      v-if="hasDates && !hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.DATES)"
      wrapper-component-class="issuable-due-date gl-text-subtle gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset"
      :start-date="startDate"
      :due-date="dueDate"
      :is-closed="isClosed"
      :icon-size="12"
    />
    <span v-else-if="detailLoading">
      <gl-skeleton-loader :width="30" :lines="1" equal-width-lines />
    </span>
    <work-item-attribute
      v-if="timeEstimate"
      anchor-id="time-estimate"
      wrapper-component="button"
      icon-name="timer"
      :icon-size="12"
      :title="timeEstimate"
      wrapper-component-class="gl-text-subtle gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset"
      :tooltip-text="__('Estimate')"
      tooltip-placement="top"
    />
    <span v-else-if="detailLoading">
      <gl-skeleton-loader :width="25" :lines="1" equal-width-lines />
    </span>
    <slot></slot>
  </div>
</template>
