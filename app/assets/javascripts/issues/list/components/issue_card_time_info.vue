<script>
import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { STATUS_CLOSED } from '~/issues/constants';
import { humanTimeframe, isInPast, localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { STATE_CLOSED } from '~/work_items/constants';
import {
  findMilestoneWidget,
  findStartAndDueDateWidget,
  findTimeTrackingWidget,
} from '~/work_items/utils';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

export default {
  components: {
    IssuableMilestone,
    WorkItemAttribute,
    GlIcon,
    GlSkeletonLoader,
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
  },
  computed: {
    milestone() {
      return this.issue.milestone || findMilestoneWidget(this.issue)?.milestone;
    },
    dueDate() {
      return this.issue.dueDate || findStartAndDueDateWidget(this.issue)?.dueDate;
    },
    datesText() {
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
    datesTooltipTitle() {
      return this.isOverdue ? `${__('Dates')} (${__('overdue')})` : __('Dates');
    },
    dateIcon() {
      return this.isOverdue ? 'calendar-overdue' : 'calendar';
    },
    startDate() {
      return findStartAndDueDateWidget(this.issue)?.startDate;
    },
    timeEstimate() {
      return (
        this.issue.humanTimeEstimate ||
        this.issue.timeStats?.humanTimeEstimate ||
        findTimeTrackingWidget(this.issue)?.humanReadableAttributes?.timeEstimate
      );
    },
  },
};
</script>

<template>
  <span class="gl-inline-flex gl-w-min gl-gap-3 gl-whitespace-nowrap">
    <slot name="weight"></slot>
    <issuable-milestone v-if="milestone" :milestone="milestone" />
    <span v-else-if="detailLoading">
      <gl-skeleton-loader :width="55" :lines="1" equal-width-lines />
    </span>
    <slot name="iteration"></slot>
    <work-item-attribute
      v-if="datesText"
      anchor-id="issuable-due-date"
      wrapper-component-class="issuable-due-date"
      :title="datesText"
      title-component-class="gl-mr-3"
      :tooltip-text="datesTooltipTitle"
      tooltip-placement="top"
    >
      <template #icon>
        <gl-icon :variant="isOverdue ? 'danger' : 'current'" :name="dateIcon" :size="12" />
      </template>
    </work-item-attribute>
    <span v-else-if="detailLoading">
      <gl-skeleton-loader :width="30" :lines="1" equal-width-lines />
    </span>
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
    <span v-else-if="detailLoading">
      <gl-skeleton-loader :width="25" :lines="1" equal-width-lines />
    </span>
    <slot></slot>
  </span>
</template>
