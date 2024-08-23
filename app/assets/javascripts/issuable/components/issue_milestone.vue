<script>
import { GlTooltip, GlIcon } from '@gitlab/ui';
import { timeFor, parsePikadayDate, dateInWords } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlIcon,
    GlTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    milestone: {
      type: Object,
      required: true,
    },
  },
  computed: {
    milestoneDue() {
      const dueDate = this.milestone.due_date || this.milestone.dueDate;

      return dueDate ? parsePikadayDate(dueDate) : null;
    },
    milestoneStart() {
      const startDate = this.milestone.start_date || this.milestone.startDate;

      return startDate ? parsePikadayDate(startDate) : null;
    },
    isMilestoneStarted() {
      if (!this.milestoneStart) {
        return false;
      }
      return Date.now() > this.milestoneStart;
    },
    isMilestonePastDue() {
      if (!this.milestoneDue) {
        return false;
      }
      return Date.now() > this.milestoneDue;
    },
    milestoneDatesAbsolute() {
      if (this.milestoneDue) {
        return `(${dateInWords(this.milestoneDue)})`;
      }
      if (this.milestoneStart) {
        return `(${dateInWords(this.milestoneStart)})`;
      }
      return '';
    },
    milestoneDatesHuman() {
      if (this.milestoneStart || this.milestoneDue) {
        if (this.milestoneDue) {
          return timeFor(
            this.milestoneDue,
            sprintf(__('Expired %{expiredOn}'), {
              expiredOn: this.timeFormatted(this.milestoneDue),
            }),
          );
        }

        return sprintf(
          this.isMilestoneStarted ? __('Started %{startsIn}') : __('Starts %{startsIn}'),
          {
            startsIn: this.timeFormatted(this.milestoneStart),
          },
        );
      }
      return '';
    },
  },
};
</script>
<template>
  <div ref="milestoneDetails" class="issue-milestone-details">
    <gl-icon :size="16" class="flex-shrink-0 gl-mr-2" name="milestone" />
    <span class="milestone-title gl-inline-block gl-truncate">{{ milestone.title }}</span>
    <gl-tooltip :target="() => $refs.milestoneDetails" placement="bottom" class="js-item-milestone">
      <span class="gl-font-bold">{{ __('Milestone') }}</span> <br />
      <span>{{ milestone.title }}</span> <br />
      <span
        v-if="milestoneStart || milestoneDue"
        :class="{
          'gl-text-red-300': isMilestonePastDue,
          'gl-text-tertiary': !isMilestonePastDue,
        }"
        ><span>{{ milestoneDatesHuman }}</span
        ><br /><span>{{ milestoneDatesAbsolute }}</span>
      </span>
    </gl-tooltip>
  </div>
</template>
