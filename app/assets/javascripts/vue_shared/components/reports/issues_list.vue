<script>
import IssuesBlock from '~/vue_shared/components/reports/report_issues.vue';
import {
  STATUS_SUCCESS,
  STATUS_FAILED,
  STATUS_NEUTRAL,
} from '~/vue_shared/components/reports/constants';

/**
 * Renders block of issues
 */

export default {
  components: {
    IssuesBlock,
  },
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
    component: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <div class="report-block-container">

    <issues-block
      v-if="unresolvedIssues.length"
      :component="component"
      :issues="unresolvedIssues"
      :status="$options.failed"
      class="js-mr-code-new-issues"
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
  </div>
</template>
