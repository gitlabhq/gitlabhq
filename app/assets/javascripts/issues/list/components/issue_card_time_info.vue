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
    milestoneDate() {
      if (this.issue.milestone?.dueDate) {
        const { dueDate, startDate } = this.issue.milestone;
        const date = dateInWords(newDateAsLocaleTime(dueDate), true);
        const remainingTime = this.milestoneRemainingTime(dueDate, startDate);
        return `${date} (${remainingTime})`;
      }
      return __('Milestone');
    },
    milestoneLink() {
      return this.issue.milestone.webPath || this.issue.milestone.webUrl;
    },
    dueDate() {
      return this.issue.dueDate && dateInWords(newDateAsLocaleTime(this.issue.dueDate), true);
    },
    showDueDateInRed() {
      return (
        isInPast(newDateAsLocaleTime(this.issue.dueDate)) && this.issue.state !== STATUS_CLOSED
      );
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
      } else if (dueDate && isToday(due)) {
        return __('Today');
      } else if (startDate && isInFuture(start)) {
        return __('Upcoming');
      } else if (dueDate) {
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
      v-if="issue.milestone"
      class="issuable-milestone gl-mr-3 gl-text-truncate gl-max-w-26 gl-display-inline-block gl-vertical-align-bottom"
      data-testid="issuable-milestone"
    >
      <gl-link
        v-gl-tooltip
        :href="milestoneLink"
        :title="milestoneDate"
        class="gl-font-sm gl-text-gray-500!"
      >
        <gl-icon name="clock" :size="12" />
        {{ issue.milestone.title }}
      </gl-link>
    </span>
    <span
      v-if="issue.dueDate"
      v-gl-tooltip
      class="issuable-due-date gl-mr-3"
      :class="{ 'gl-text-red-500': showDueDateInRed }"
      :title="__('Due date')"
      data-testid="issuable-due-date"
    >
      <gl-icon name="calendar" :size="12" />
      {{ dueDate }}
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
