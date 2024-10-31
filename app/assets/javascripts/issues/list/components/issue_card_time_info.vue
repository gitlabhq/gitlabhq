<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { STATUS_CLOSED } from '~/issues/constants';
import { humanTimeframe, isInPast, localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { STATE_CLOSED } from '~/work_items/constants';
import { isMilestoneWidget, isStartAndDueDateWidget } from '~/work_items/utils';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';

export default {
  components: {
    GlIcon,
    IssuableMilestone,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    issue: {
      type: Object,
      required: true,
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
    <span
      v-if="dueDateText"
      v-gl-tooltip
      class="issuable-due-date gl-mr-3"
      :title="dueDateTitle"
      data-testid="issuable-due-date"
    >
      <gl-icon :variant="isOverdue ? 'danger' : 'current'" :name="dateIcon" :size="12" />
      {{ dueDateText }}
    </span>
    <span
      v-if="timeEstimate"
      v-gl-tooltip
      class="gl-mr-3"
      :title="__('Estimate')"
      data-testid="time-estimate"
    >
      <gl-icon name="timer" :size="12" />
      {{ timeEstimate }}
    </span>
    <slot></slot>
  </span>
</template>
