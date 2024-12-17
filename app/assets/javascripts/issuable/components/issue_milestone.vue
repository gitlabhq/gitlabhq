<script>
import { localeDateFormat, newDate, timeFor } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

export default {
  components: {
    WorkItemAttribute,
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

      return dueDate ? newDate(dueDate) : null;
    },
    milestoneStart() {
      const startDate = this.milestone.start_date || this.milestone.startDate;

      return startDate ? newDate(startDate) : null;
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
        return `(${localeDateFormat.asDate.format(this.milestoneDue)})`;
      }
      if (this.milestoneStart) {
        return `(${localeDateFormat.asDate.format(this.milestoneStart)})`;
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
  <work-item-attribute
    anchor-id="board-card-milestone"
    wrapper-component="div"
    wrapper-component-class="issue-milestone-details gl-flex gl-max-w-15 gl-gap-2 gl-items-center"
    icon-name="milestone"
    icon-class="flex-shrink-0"
    :title="milestone.title"
    title-component-class="milestone-title gl-inline-block gl-truncate"
  >
    <template #tooltip-text>
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
    </template>
  </work-item-attribute>
</template>
