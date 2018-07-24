<script>
import IssuesBlock from '~/vue_shared/components/reports/report_issues.vue';

import SastContainerInfo from 'ee/vue_shared/security_reports/components/sast_container_info.vue';
import { SAST_CONTAINER } from 'ee/vue_shared/security_reports/store/constants';

/**
 * Renders block of issues
 */

export default {
  components: {
    IssuesBlock,
    SastContainerInfo,
  },
  sastContainer: SAST_CONTAINER,
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
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isFullReportVisible: false,
    };
  },
  computed: {
    unresolvedIssuesStatus() {
      return this.type === 'license' ? 'neutral' : 'failed';
    },
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
    <sast-container-info v-if="type === $options.sastContainer" />

    <issues-block
      v-if="unresolvedIssues.length"
      :type="type"
      :status="unresolvedIssuesStatus"
      :issues="unresolvedIssues"
      class="js-mr-code-new-issues"
    />

    <issues-block
      v-if="isFullReportVisible"
      :type="type"
      :issues="allIssues"
      class="js-mr-code-all-issues"
      status="failed"
    />

    <issues-block
      v-if="neutralIssues.length"
      :type="type"
      :issues="neutralIssues"
      class="js-mr-code-non-issues"
      status="neutral"
    />

    <issues-block
      v-if="resolvedIssues.length"
      :type="type"
      :issues="resolvedIssues"
      class="js-mr-code-resolved-issues"
      status="success"
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
