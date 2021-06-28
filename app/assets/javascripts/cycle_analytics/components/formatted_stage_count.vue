<script>
import { s__, n__, sprintf } from '~/locale';

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
      } else if (this.stageCount > 1000) {
        return sprintf(s__('ValueStreamAnalytics|%{stageCount} items'), { stageCount: '1000+' });
      }

      return n__('%d item', '%d items', this.stageCount);
    },
  },
};
</script>

<template>
  <span>{{ formattedStageCount }}</span>
</template>
