<script>
import { formatDurationMs } from '../../utils/value_format';

export default {
  name: 'DurationMsPresenter',
  props: {
    data: {
      required: true,
      type: Number,
    },
  },
  computed: {
    formatted() {
      return formatDurationMs(this.data);
    },
  },
};
</script>
<template>
  <span>{{ formatted }}</span>
</template>
