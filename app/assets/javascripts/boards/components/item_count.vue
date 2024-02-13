<script>
export default {
  name: 'IssueCount',
  props: {
    maxIssueCount: {
      type: Number,
      required: false,
      default: 0,
    },
    itemsSize: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    isMaxLimitSet() {
      return this.maxIssueCount !== 0;
    },
    issuesExceedMax() {
      return this.isMaxLimitSet && this.itemsSize > this.maxIssueCount;
    },
  },
};
</script>

<template>
  <div class="item-count text-nowrap">
    <span :class="{ 'gl-text-red-700': issuesExceedMax }" data-testid="board-items-count">
      {{ itemsSize }}
    </span>
    <span v-if="isMaxLimitSet" class="max-issue-size">
      <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
      {{ `/ ${maxIssueCount}` }}
      <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
    </span>
  </div>
</template>
