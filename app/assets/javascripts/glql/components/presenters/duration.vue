<script>
import { timeIntervalInWords } from '~/lib/utils/datetime/date_format_utility';

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
      return timeIntervalInWords(this.data);
    },
  },
};
</script>
<template>
  <span>{{ formatted }}</span>
</template>
