<script>
import { GlTooltip } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { timeFor, parsePikadayDate, dateInWords } from '~/lib/utils/datetime_utility';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
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
      } else if (this.milestoneStart) {
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
    <icon :size="16" class="inline icon" name="clock" />
    <span class="milestone-title d-inline-block">{{ milestone.title }}</span>
    <gl-tooltip :target="() => $refs.milestoneDetails" placement="bottom" class="js-item-milestone">
      <span class="bold">{{ __('Milestone') }}</span> <br />
      <span>{{ milestone.title }}</span> <br />
      <span
        v-if="milestoneStart || milestoneDue"
        :class="{
          'text-danger-muted': isMilestonePastDue,
          'text-tertiary': !isMilestonePastDue,
        }"
        ><span>{{ milestoneDatesHuman }}</span
        ><br /><span>{{ milestoneDatesAbsolute }}</span>
      </span>
    </gl-tooltip>
  </div>
</template>
