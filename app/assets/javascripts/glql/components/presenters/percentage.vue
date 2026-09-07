<script>
import { formatRate } from '../../utils/value_format';

export default {
  name: 'PercentagePresenter',
  props: {
    data: {
      required: true,
      // The aggregation GraphQL serializes `rate` metrics as BigDecimal strings
      // (e.g. completionRate, acceptanceRate), so accept both.
      type: [Number, String],
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
