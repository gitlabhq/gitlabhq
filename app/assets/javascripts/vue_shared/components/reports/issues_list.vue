<script>
import IssuesBlock from '~/vue_shared/components/reports/report_issues.vue';
import {
  STATUS_SUCCESS,
  STATUS_FAILED,
  STATUS_NEUTRAL,
} from '~/vue_shared/components/reports/constants';
import { componentNames } from 'ee/vue_shared/components/reports/issue_body';

import SastContainerInfo from 'ee/vue_shared/security_reports/components/sast_container_info.vue';

/**
 * Renders block of issues
 */

export default {
  components: {
    IssuesBlock,
    SastContainerInfo,
  },
  componentNames,
  success: STATUS_SUCCESS,
  failed: STATUS_FAILED,
  neutral: STATUS_NEUTRAL,
  props: {
    unresolvedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    resolvedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    neutralIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    allIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    component: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isFullReportVisible: false,
    };
  },
  methods: {
    openFullReport() {
      this.isFullReportVisible = true;
    },
  },
};
</script>
<template>
  <div class="report-block-container">
    <sast-container-info v-if="component === $options.componentNames.SastContainerIssueBody" />
    <issues-block
      v-if="unresolvedIssues.length"
      :component="component"
      :issues="unresolvedIssues"
      :status="$options.failed"
      class="js-mr-code-new-issues"
    />

    <issues-block
      v-if="isFullReportVisible"
      :component="component"
      :issues="allIssues"
      :status="$options.failed"
      class="js-mr-code-all-issues"
    />

    <issues-block
      v-if="neutralIssues.length"
      :component="component"
      :issues="neutralIssues"
      :status="$options.neutral"
      class="js-mr-code-non-issues"
    />

    <issues-block
      v-if="resolvedIssues.length"
      :component="component"
      :issues="resolvedIssues"
      :status="$options.success"
      class="js-mr-code-resolved-issues"
    />

    <button
      v-if="allIssues.length && !isFullReportVisible"
      type="button"
      class="btn-link btn-blank prepend-left-10 js-expand-full-list break-link"
      @click="openFullReport"
    >
      {{ s__("ciReport|Show complete code vulnerabilities report") }}
    </button>
  </div>
</template>
