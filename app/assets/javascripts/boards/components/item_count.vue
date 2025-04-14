<script>
import { GlSprintf } from '@gitlab/ui';

export default {
  name: 'IssueCount',
  components: {
    GlSprintf,
  },
  props: {
    maxCount: {
      type: Number,
      required: false,
      default: 0,
    },
    currentCount: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  computed: {
    isMaxLimitSet() {
      return this.maxCount !== 0;
    },
    exceedsMax() {
      return this.isMaxLimitSet && this.currentCount > this.maxCount;
    },
  },
};
</script>

<template>
  <div class="item-count text-nowrap">
    <span :class="{ 'gl-text-red-700': exceedsMax }" data-testid="board-items-count">
      {{ currentCount }}
    </span>
    <span v-if="isMaxLimitSet" class="max-issue-size">
      <gl-sprintf :message="__('/ %{maxCount}')">
        <template #maxCount>{{ maxCount }}</template>
      </gl-sprintf>
    </span>
  </div>
</template>
