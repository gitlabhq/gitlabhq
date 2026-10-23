<script>
import { newDate, localeDateFormat } from '~/lib/utils/datetime_utility';

export default {
  name: 'FormatTime',
  props: {
    timestamp: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    formattedTime() {
      return this.timestamp ? localeDateFormat.asDate.format(newDate(this.timestamp)) : '';
    },
  },
};
</script>
<template>
  <span>{{ formattedTime }}</span>
</template>
