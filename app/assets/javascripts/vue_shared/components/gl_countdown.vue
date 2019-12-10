<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { calculateRemainingMilliseconds, formatTime } from '~/lib/utils/datetime_utility';

/**
 * Counts down to a given end date.
 */
export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },

  props: {
    endDateString: {
      type: String,
      required: true,
      validator(value) {
        return !Number.isNaN(new Date(value).getTime());
      },
    },
  },

  data() {
    return {
      remainingTime: formatTime(0),
      countdownUpdateIntervalId: null,
    };
  },

  mounted() {
    const updateRemainingTime = () => {
      const remainingMilliseconds = calculateRemainingMilliseconds(this.endDateString);
      this.remainingTime = formatTime(remainingMilliseconds);
    };

    updateRemainingTime();
    this.countdownUpdateIntervalId = window.setInterval(updateRemainingTime, 1000);
  },

  beforeDestroy() {
    window.clearInterval(this.countdownUpdateIntervalId);
  },
};
</script>

<template>
  <time v-gl-tooltip :datetime="endDateString" :title="endDateString"> {{ remainingTime }} </time>
</template>
