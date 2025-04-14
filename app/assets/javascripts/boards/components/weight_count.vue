<script>
export default {
  name: 'IssueWeightCount',
  props: {
    issueWeight: {
      type: Number,
      required: true,
      default: 0,
    },
    maxIssueWeight: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    maxLimitText() {
      return this.maxIssueWeight !== 0 ? `/ ${this.maxIssueWeight}` : '';
    },
    issuesExceedMax() {
      return this.maxIssueWeight !== 0 && this.issueWeight > this.maxIssueWeight;
    },
  },
};
</script>

<template>
  <div class="weight-count text-nowrap">
    <span :class="{ 'gl-text-red-700': issuesExceedMax }" data-testid="board-weight-count">
      {{ issueWeight }}
    </span>
    <span class="max-issue-size">
      {{ maxLimitText }}
    </span>
  </div>
</template>
