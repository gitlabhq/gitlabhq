<script>
import { GlLink, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import {
  getTimeRemainingInWords,
  isInFuture,
  isInPast,
  isToday,
  localeDateFormat,
  newDate,
} from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';

export default {
  name: 'IssuableMilestone',
  components: {
    GlLink,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    milestone: {
      type: Object,
      required: true,
    },
  },
  computed: {
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
  <span class="issuable-milestone gl-mr-3" data-testid="issuable-milestone">
    <gl-link
      v-gl-tooltip
      :href="milestoneLink"
      :title="milestoneDate"
      class="gl-text-sm !gl-text-gray-500"
      @click.stop
    >
      <gl-icon name="milestone" :size="12" class="gl-mr-2" />{{ milestone.title }}
    </gl-link>
  </span>
</template>
