<script>
import { tierBandFormatter } from '../../utils/tier_band';

export default {
  name: 'TierBandPresenter',
  props: {
    data: {
      required: true,
      type: String,
    },
    parameters: {
      required: true,
      type: Object,
    },
  },
  computed: {
    label() {
      return tierBandFormatter(this.parameters.thresholds)(this.data);
    },
  },
};
</script>
<template>
  <span>{{ label }}</span>
</template>
