<script>
import { GlProgressBar } from '@gitlab/ui';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import tooltip from '../../../vue_shared/directives/tooltip';
import { s__, sprintf } from '~/locale';

export default {
  name: 'TimeTrackingComparisonPane',
  components: {
    GlProgressBar,
  },
  directives: {
    tooltip,
  },
  props: {
    timeSpent: {
      type: Number,
      required: true,
    },
    timeEstimate: {
      type: Number,
      required: true,
    },
    timeSpentHumanReadable: {
      type: String,
      required: true,
    },
    timeEstimateHumanReadable: {
      type: String,
      required: true,
    },
    limitToHours: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    parsedTimeRemaining() {
      const diffSeconds = this.timeEstimate - this.timeSpent;
      return parseSeconds(diffSeconds, { limitToHours: this.limitToHours });
    },
    timeRemainingHumanReadable() {
      return stringifyTime(this.parsedTimeRemaining);
    },
    timeRemainingTooltip() {
      const { timeRemainingHumanReadable, timeRemainingMinutes } = this;
      return timeRemainingMinutes < 0
        ? sprintf(s__('TimeTracking|Over by %{timeRemainingHumanReadable}'), {
            timeRemainingHumanReadable,
          })
        : sprintf(s__('TimeTracking|Time remaining: %{timeRemainingHumanReadable}'), {
            timeRemainingHumanReadable,
          });
    },
    /* Diff values for comparison meter */
    timeRemainingMinutes() {
      return this.timeEstimate - this.timeSpent;
    },
    timeRemainingPercent() {
      return Math.floor((this.timeSpent / this.timeEstimate) * 100);
    },
    timeRemainingStatusClass() {
      return this.timeEstimate >= this.timeSpent ? 'within_estimate' : 'over_estimate';
    },
    progressBarVariant() {
      return this.timeRemainingPercent > 100 ? 'danger' : 'primary';
    },
  },
};
</script>

<template>
  <div class="time-tracking-comparison-pane">
    <div
      v-tooltip
      :title="timeRemainingTooltip"
      :class="timeRemainingStatusClass"
      class="compare-meter"
    >
      <gl-progress-bar :value="timeRemainingPercent" :variant="progressBarVariant" />
      <div class="compare-display-container">
        <div class="compare-display float-left">
          <span class="compare-label">{{ s__('TimeTracking|Spent') }}</span>
          <span class="compare-value spent">{{ timeSpentHumanReadable }}</span>
        </div>
        <div class="compare-display estimated float-right">
          <span class="compare-label">{{ s__('TimeTrackingEstimated|Est') }}</span>
          <span class="compare-value">{{ timeEstimateHumanReadable }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
