<script>
import { GlIcon } from '@gitlab/ui';
import { STATUS_CLOSED } from '~/issues/constants';
import { humanTimeframe, isInPast, localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { STATE_CLOSED } from '~/work_items/constants';
import { isMilestoneWidget, isStartAndDueDateWidget } from '~/work_items/utils';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

export default {
  components: {
    IssuableMilestone,
    WorkItemAttribute,
    GlIcon,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    isWorkItemList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    milestone() {
      return this.issue.milestone || this.issue.widgets?.find(isMilestoneWidget)?.milestone;
    },
    dueDate() {
      return this.issue.dueDate || this.issue.widgets?.find(isStartAndDueDateWidget)?.dueDate;
    },
    dueDateText() {
      if (this.startDate) {
        return humanTimeframe(newDate(this.startDate), newDate(this.dueDate));
      }
      if (this.dueDate) {
        return localeDateFormat.asDate.format(newDate(this.dueDate));
      }
      return null;
    },
    isClosed() {
      return this.issue.state === STATUS_CLOSED || this.issue.state === STATE_CLOSED;
    },
    isOverdue() {
      if (!this.dueDate) {
        return false;
      }
      return isInPast(newDate(this.dueDate)) && !this.isClosed;
    },
    dueDateTitle() {
      return this.isOverdue ? `${__('Due date')} (${__('overdue')})` : __('Due date');
    },
    dateIcon() {
      return this.isOverdue ? 'calendar-overdue' : 'calendar';
    },
    startDate() {
      return this.issue.widgets?.find(isStartAndDueDateWidget)?.startDate;
    },
    timeEstimate() {
      return this.issue.humanTimeEstimate || this.issue.timeStats?.humanTimeEstimate;
    },
  },
};
</script>

<template>
  <span>
    <issuable-milestone v-if="milestone" :milestone="milestone" />
    <work-item-attribute
      v-if="dueDateText"
      anchor-id="issuable-due-date"
      :title="dueDateText"
      title-component-class="issuable-due-date gl-mr-3"
      :tooltip-text="dueDateTitle"
      tooltip-placement="top"
    >
      <template #icon>
        <gl-icon :variant="isOverdue ? 'danger' : 'current'" :name="dateIcon" :size="12" />
      </template>
    </work-item-attribute>
    <work-item-attribute
      v-if="timeEstimate"
      anchor-id="time-estimate"
      :title="timeEstimate"
      title-component-class="gl-mr-3"
      :tooltip-text="__('Estimate')"
      tooltip-placement="top"
    >
      <template #icon>
        <gl-icon name="timer" :size="12" />
      </template>
    </work-item-attribute>
    <slot></slot>
  </span>
</template>
