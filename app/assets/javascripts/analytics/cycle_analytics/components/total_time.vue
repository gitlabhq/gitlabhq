<script>
import { n__, s__ } from '~/locale';

export default {
  props: {
    time: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    hasData() {
      return Object.keys(this.time).length;
    },
    calculatedTime() {
      const { days = null, mins = null, hours = null, seconds = null } = this.time;

      if (days) {
        return {
          duration: days,
          units: n__('day', 'days', days),
        };
      }

      if (hours) {
        return {
          duration: hours,
          units: n__('Time|hr', 'Time|hrs', hours),
        };
      }

      if (mins && !days) {
        return {
          duration: mins,
          units: n__('Time|min', 'Time|mins', mins),
        };
      }

      if ((seconds && this.hasData === 1) || seconds === 0) {
        return {
          duration: seconds,
          units: s__('Time|s'),
        };
      }

      return { duration: null, units: null };
    },
  },
};
</script>
<template>
  <span>
    <template v-if="hasData">
      {{ calculatedTime.duration }} <span>{{ calculatedTime.units }}</span>
    </template>
    <template v-else> -- </template>
  </span>
</template>
