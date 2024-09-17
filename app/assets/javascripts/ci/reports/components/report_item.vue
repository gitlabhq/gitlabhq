<script>
import {
  components,
  componentNames,
  iconComponents,
  iconComponentNames,
} from 'ee_else_ce/ci/reports/components/issue_body';

export default {
  name: 'ReportItem',
  components: {
    ...components,
    ...iconComponents,
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
      validator: (value) => value === '' || Object.values(componentNames).includes(value),
    },
    iconComponent: {
      type: String,
      required: false,
      default: iconComponentNames.IssueStatusIcon,
      validator: (value) => Object.values(iconComponentNames).includes(value),
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
  <li class="report-block-list-issue !gl-p-3" data-testid="report-item-row">
    <component
      :is="iconComponent"
      v-if="showReportSectionStatusIcon"
      :status="status"
      :status-icon-size="statusIconSize"
      class="gl-mr-2"
    />

    <component :is="component" v-if="component" :issue="issue" :status="status" :is-new="isNew" />
  </li>
</template>
