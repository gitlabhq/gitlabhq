<script>
export default {
  name: 'IssueCount',
  props: {
    maxIssueCount: {
      type: Number,
      required: false,
      default: 0,
    },
    issuesSize: {
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
      return this.isMaxLimitSet && this.issuesSize > this.maxIssueCount;
    },
  },
};
</script>

<template>
  <div class="issue-count">
    <span class="js-issue-size" :class="{ 'text-danger': issuesExceedMax }">
      {{ issuesSize }}
    </span>
    <span v-if="isMaxLimitSet" class="js-max-issue-size">
      {{ maxIssueCount }}
    </span>
  </div>
</template>
