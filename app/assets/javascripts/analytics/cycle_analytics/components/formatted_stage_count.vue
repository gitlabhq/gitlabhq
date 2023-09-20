<script>
import { s__, n__, sprintf, formatNumber } from '~/locale';

export default {
  props: {
    stageCount: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    formattedStageCount() {
      if (!this.stageCount) {
        return '-';
      }
      if (this.stageCount > 1000) {
        return sprintf(s__('ValueStreamAnalytics|%{stageCount}+ items'), {
          stageCount: formatNumber(1000),
        });
      }

      return sprintf(n__('%{count} item', '%{count} items', this.stageCount), {
        count: formatNumber(this.stageCount),
      });
    },
  },
};
</script>

<template>
  <span>{{ formattedStageCount }}</span>
</template>
