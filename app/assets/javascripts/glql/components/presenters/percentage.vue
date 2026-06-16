<script>
import { formatRate } from '../../utils/value_format';

export default {
  name: 'PercentagePresenter',
  props: {
    data: {
      required: true,
      type: Number,
    },
  },
  computed: {
    formattedPercentage() {
      return formatRate(this.data);
    },
  },
};
</script>
<template>
  <span>{{ formattedPercentage }}</span>
</template>
