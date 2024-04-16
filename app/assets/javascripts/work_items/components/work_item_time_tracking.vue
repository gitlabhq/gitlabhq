<script>
import { GlProgressBar, GlTooltipDirective } from '@gitlab/ui';
import { outputChronicDuration } from '~/chronic_duration';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { s__, sprintf } from '~/locale';

const options = { format: 'short' };

export default {
  components: {
    GlProgressBar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    timeEstimate: {
      type: Number,
      required: false,
      default: 0,
    },
    totalTimeSpent: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    humanTimeEstimate() {
      return outputChronicDuration(this.timeEstimate, options);
    },
    humanTotalTimeSpent() {
      return outputChronicDuration(this.totalTimeSpent, options) ?? '0h';
    },
    progressBarTooltipText() {
      const timeDifference = this.totalTimeSpent - this.timeEstimate;
      const time = outputChronicDuration(Math.abs(timeDifference), options);
      return isPositiveInteger(timeDifference)
        ? sprintf(s__('TimeTracking|%{time} over'), { time })
        : sprintf(s__('TimeTracking|%{time} remaining'), { time });
    },
    progressBarVariant() {
      return this.timeRemainingPercent > 100 ? 'danger' : 'primary';
    },
    timeRemainingPercent() {
      return Math.floor((this.totalTimeSpent / this.timeEstimate) * 100);
    },
  },
};
</script>

<template>
  <div>
    <h3 class="gl-heading-5 gl-mb-2!">
      {{ __('Time tracking') }}
    </h3>
    <div
      class="gl-display-flex gl-align-items-center gl-gap-2 gl-font-sm"
      data-testid="time-tracking-body"
    >
      <template v-if="totalTimeSpent || timeEstimate">
        <span class="gl-text-secondary">{{ s__('TimeTracking|Spent') }}</span>
        {{ humanTotalTimeSpent }}
        <template v-if="timeEstimate">
          <gl-progress-bar
            v-gl-tooltip="progressBarTooltipText"
            class="gl-flex-grow-1 gl-mx-2"
            :value="timeRemainingPercent"
            :variant="progressBarVariant"
          />
          <span class="gl-text-secondary">{{ s__('TimeTracking|Estimate') }}</span>
          {{ humanTimeEstimate }}
        </template>
      </template>
      <span v-else class="gl-text-secondary">
        {{ s__('TimeTracking|To manage time, use /spend or /estimate.') }}
      </span>
    </div>
  </div>
</template>
