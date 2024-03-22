<script>
import { GlLink, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { STATUS_CLOSED } from '~/issues/constants';
import {
  dateInWords,
  getTimeRemainingInWords,
  isInFuture,
  isInPast,
  isToday,
  newDateAsLocaleTime,
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
        const date = dateInWords(newDateAsLocaleTime(dueDate), true);
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
      return this.dueDate && dateInWords(newDateAsLocaleTime(this.dueDate), true);
    },
    isClosed() {
      return this.issue.state === STATUS_CLOSED || this.issue.state === STATE_CLOSED;
    },
    showDueDateInRed() {
      return isInPast(newDateAsLocaleTime(this.dueDate)) && !this.isClosed;
    },
    timeEstimate() {
      return this.issue.humanTimeEstimate || this.issue.timeStats?.humanTimeEstimate;
    },
  },
  methods: {
    milestoneRemainingTime(dueDate, startDate) {
      const due = newDateAsLocaleTime(dueDate);
      const start = newDateAsLocaleTime(startDate);

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
    <span
      v-if="milestone"
      class="issuable-milestone gl-mr-3 gl-text-truncate gl-max-w-26 gl-display-inline-block gl-vertical-align-bottom"
      data-testid="issuable-milestone"
    >
      <gl-link
        v-gl-tooltip
        :href="milestoneLink"
        :title="milestoneDate"
        class="gl-font-sm gl-text-gray-500!"
      >
        <gl-icon name="milestone" :size="12" />
        {{ milestone.title }}
      </gl-link>
    </span>
    <span
      v-if="dueDate"
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
