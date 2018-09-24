<script>
import IssueDueDate from './issue_due_date.vue';
import IssueTimeEstimate from './issue_time_estimate.vue';

export default {
  components: {
    IssueDueDate,
    IssueTimeEstimate,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  methods: {
    emitIssueWight(e) {
      this.$emit('filterweight', e);
    },
  },
};
</script>

<template>
  <span class="append-bottom-8 board-info-items">
    <issue-due-date
      v-if="issue.dueDate"
      :date="issue.dueDate"
    />
    <issue-time-estimate
      v-if="issue.timeEstimate"
      :estimate="issue.timeEstimate" />
  </span>
</template>
