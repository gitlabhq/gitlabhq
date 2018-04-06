<script>
import IssuesBlock from './report_issues.vue';
import SastContainerInfo from './sast_container_info.vue';
import { SAST_CONTAINER } from '../store/constants';

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
    isFullReportVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    type: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="report-block-container">
    <sast-container-info v-if="type === $options.sastContainer" />

    <issues-block
      class="js-mr-code-new-issues"
      v-if="unresolvedIssues.length"
      :type="type"
      status="failed"
      :issues="unresolvedIssues"
    />

    <issues-block
      class="js-mr-code-all-issues"
      v-if="isFullReportVisible"
      :type="type"
      status="failed"
      :issues="allIssues"
    />

    <issues-block
      class="js-mr-code-non-issues"
      v-if="neutralIssues.length"
      :type="type"
      status="neutral"
      :issues="neutralIssues"
    />

    <issues-block
      class="js-mr-code-resolved-issues"
      v-if="resolvedIssues.length"
      :type="type"
      status="success"
      :issues="resolvedIssues"
    />
  </div>
</template>
