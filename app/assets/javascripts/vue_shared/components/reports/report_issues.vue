<script>
import IssueStatusIcon from '~/vue_shared/components/reports/issue_status_icon.vue';
import { components, componentNames } from 'ee/vue_shared/components/reports/issue_body';

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
        />
      </li>
    </ul>
  </div>
</template>
