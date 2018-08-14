<script>
import { formatRelevantDigits } from '~/lib/utils/number_utils';

export default {
  name: 'TrackInfo',
  props: {
    track: {
      type: Object,
      required: true,
    },
  },
  computed: {
    summaryMetrics() {
      return `Avg: ${formatRelevantDigits(this.track.average)} · Max: ${formatRelevantDigits(
        this.track.max,
      )}`;
    },
  },
};
</script>
<template>
  <span>
    <slot>
      <strong> {{ track.metricTag }} </strong>
    </slot>
    {{ summaryMetrics }}
  </span>
</template>

