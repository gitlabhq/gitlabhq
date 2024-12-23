<script>
import { GlProgressBar, GlTooltipDirective } from '@gitlab/ui';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import { s__, sprintf } from '~/locale';

export default {
  name: 'TimeTrackingComparisonPane',
  components: {
    GlProgressBar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
  <div class="gl-mt-2" data-testid="timeTrackingComparisonPane">
    <div
      v-gl-tooltip
      data-testid="compareMeter"
      :title="timeRemainingTooltip"
      :class="timeRemainingStatusClass"
      class="compare-meter"
    >
      <gl-progress-bar
        data-testid="timeRemainingProgress"
        :value="timeRemainingPercent"
        :variant="progressBarVariant"
      />
      <div class="compare-display-container gl-mt-2 gl-flex gl-justify-between">
        <div class="gl-float-left">
          <span class="gl-text-subtle">{{ s__('TimeTracking|Spent') }}</span>
          <span class="compare-value spent">{{ timeSpentHumanReadable }}</span>
        </div>
        <div class="estimated gl-float-right">
          <span class="gl-text-subtle">{{ s__('TimeTrackingEstimated|Est') }}</span>
          <span class="compare-value">{{ timeEstimateHumanReadable }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
