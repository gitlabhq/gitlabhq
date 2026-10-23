<script>
import { newDate, approximateDuration, differenceInSeconds } from '~/lib/utils/datetime_utility';

export default {
  name: 'FormatTimeRange',
  props: {
    startTimestamp: {
      type: String,
      required: false,
      default: '',
    },
    endTimestamp: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isValidRange() {
      return this.startTimestamp && this.endTimestamp;
    },
    formattedRange() {
      return this.isValidRange
        ? approximateDuration(
            differenceInSeconds(newDate(this.startTimestamp), newDate(this.endTimestamp)),
          )
        : '';
    },
  },
};
</script>
<template>
  <span>{{ formattedRange }}</span>
</template>
