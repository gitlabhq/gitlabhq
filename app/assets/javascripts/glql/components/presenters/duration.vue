<script>
import { formatDuration } from '../../utils/value_format';

export default {
  name: 'DurationPresenter',
  props: {
    data: {
      required: true,
      type: Number,
    },
  },
  computed: {
    formatted() {
      return formatDuration(this.data);
    },
  },
};
</script>
<template>
  <span>{{ formatted }}</span>
</template>
