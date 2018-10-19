<script>
import { calculateRemainingMilliseconds, formatTime } from '~/lib/utils/datetime_utility';

/**
 * Counts down to a given end date.
 */
export default {
  props: {
    endDate: {
      type: String,
      required: true,
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
      const remainingMilliseconds = calculateRemainingMilliseconds(this.endDate);
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
  <time
    v-gl-tooltip
    :datetime="endDate"
    :title="endDate"
  >
    {{ remainingTime }}
  </time>
</template>
