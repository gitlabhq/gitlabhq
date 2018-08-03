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
    newIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
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
    <sast-container-info v-if="component === $options.componentNames.SastContainerIssueBody" />
    <issues-block
      v-if="newIssues.length"
      :component="component"
      :issues="newIssues"
      class="js-mr-code-new-issues"
      status="failed"
      is-new
    />

    <issues-block
      v-if="newIssues.length"
      :component="component"
      :issues="newIssues"
      class="js-mr-code-new-issues"
      status="failed"
      is-new
    />

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
