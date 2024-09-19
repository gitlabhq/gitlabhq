<script>
import { GlLink, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { STATUS_CLOSED } from '~/issues/constants';
import {
  getTimeRemainingInWords,
  humanTimeframe,
  isInFuture,
  isInPast,
  isToday,
  localeDateFormat,
  newDate,
} from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { STATE_CLOSED } from '~/work_items/constants';
import { isMilestoneWidget, isStartAndDueDateWidget } from '~/work_items/utils';

export default {
  components: {
    GlLink,
    GlIcon,
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
    milestoneDate() {
      if (this.milestone.dueDate) {
        const { dueDate, startDate } = this.milestone;
        const date = localeDateFormat.asDate.format(newDate(dueDate));
        const remainingTime = this.milestoneRemainingTime(dueDate, startDate);
        return `${date} (${remainingTime})`;
      }
      return __('Milestone');
    },
    milestoneLink() {
      return this.milestone.webPath || this.milestone.webUrl;
    },
    dueDate() {
      return this.issue.dueDate || this.issue.widgets?.find(isStartAndDueDateWidget)?.dueDate;
    },
    dueDateText() {
      if (this.startDate) {
        return humanTimeframe(this.startDate, this.dueDate);
      }
      if (this.dueDate) {
        return localeDateFormat.asDate.format(newDate(this.dueDate));
      }
      return null;
    },
    isClosed() {
      return this.issue.state === STATUS_CLOSED || this.issue.state === STATE_CLOSED;
    },
    showDueDateInRed() {
      if (!this.dueDate) {
        return false;
      }
      return isInPast(newDate(this.dueDate)) && !this.isClosed;
    },
    startDate() {
      return this.issue.widgets?.find(isStartAndDueDateWidget)?.startDate;
    },
    timeEstimate() {
      return this.issue.humanTimeEstimate || this.issue.timeStats?.humanTimeEstimate;
    },
  },
  methods: {
    milestoneRemainingTime(dueDate, startDate) {
      const due = newDate(dueDate);
      const start = newDate(startDate);

      if (dueDate && isInPast(due)) {
        return __('Past due');
      }
      if (dueDate && isToday(due)) {
        return __('Today');
      }
      if (startDate && isInFuture(start)) {
        return __('Upcoming');
      }
      if (dueDate) {
        return getTimeRemainingInWords(due);
      }
      return '';
    },
  },
};
</script>

<template>
  <span>
    <span v-if="milestone" class="issuable-milestone gl-mr-3" data-testid="issuable-milestone">
      <gl-link
        v-gl-tooltip
        :href="milestoneLink"
        :title="milestoneDate"
        class="gl-text-sm !gl-text-gray-500"
        @click.stop
      >
        <gl-icon name="milestone" :size="12" />
        {{ milestone.title }}
      </gl-link>
    </span>
    <span
      v-if="dueDateText"
      v-gl-tooltip
      class="issuable-due-date gl-mr-3"
      :class="{ 'gl-text-red-500': showDueDateInRed }"
      :title="__('Due date')"
      data-testid="issuable-due-date"
    >
      <gl-icon name="calendar" :size="12" />
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
