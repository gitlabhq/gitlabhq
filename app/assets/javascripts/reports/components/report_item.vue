<script>
import { components, componentNames } from 'ee_else_ce/reports/components/issue_body';
import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';

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
      default: 24,
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
  <li
    :class="{ 'is-dismissed': issue.isDismissed }"
    class="report-block-list-issue align-items-center"
    data-qa-selector="report_item_row"
  >
    <issue-status-icon
      v-if="showReportSectionStatusIcon"
      :status="status"
      :status-icon-size="statusIconSize"
      class="append-right-default"
    />

    <component :is="component" v-if="component" :issue="issue" :status="status" :is-new="isNew" />
  </li>
</template>
