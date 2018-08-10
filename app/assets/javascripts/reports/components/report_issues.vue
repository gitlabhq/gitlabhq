<script>
import IssueStatusIcon from './issue_status_icon.vue';
import { components, componentNames } from './issue_body';

export default {
  name: 'ReportIssues',
  components: {
    IssueStatusIcon,
    ...components,
  },
  props: {
    issues: {
      type: Array,
      required: true,
    },
    component: {
      type: String,
      required: false,
      default: '',
      validator: value => value === '' || Object.values(componentNames).includes(value),
    },
    // failed || success
    status: {
      type: String,
      required: true,
    },
    isNew: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div>
    <ul class="report-block-list">
      <li
        v-for="(issue, index) in issues"
        :class="{ 'is-dismissed': issue.isDismissed }"
        :key="index"
        class="report-block-list-issue"
      >
        <issue-status-icon
          :status="issue.status || status"
          class="append-right-5"
        />

        <component
          v-if="component"
          :is="component"
          :issue="issue"
          :status="issue.status || status"
          :is-new="isNew"
        />
      </li>
    </ul>
  </div>
</template>
