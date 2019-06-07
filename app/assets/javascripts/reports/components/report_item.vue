<script>
import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';
import { components, componentNames } from '~/reports/components/issue_body';

export default {
  name: 'ReportItem',
  components: {
    IssueStatusIcon,
    ...components,
  },
  props: {
    issue: {
      type: Object,
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
    statusIconSize: {
      type: Number,
      required: false,
      default: 32,
    },
    isNew: {
      type: Boolean,
      required: false,
      default: false,
    },
    showReportSectionStatusIcon: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>
<template>
  <li :class="{ 'is-dismissed': issue.isDismissed }" class="report-block-list-issue">
    <issue-status-icon
      v-if="showReportSectionStatusIcon"
      :status="status"
      :status-icon-size="statusIconSize"
      class="append-right-5"
    />

    <component :is="component" v-if="component" :issue="issue" :status="status" :is-new="isNew" />
  </li>
</template>
