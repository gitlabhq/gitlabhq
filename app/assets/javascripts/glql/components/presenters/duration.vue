<script>
import { formatDuration } from '../../utils/value_format';

export default {
  name: 'DurationPresenter',
  props: {
    data: {
      required: true,
      // Measurement-object leaves (e.g. durationMean/Min/Max/Sum) are serialized
      // as BigDecimal strings by the aggregation GraphQL, so accept both.
      type: [Number, String],
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
