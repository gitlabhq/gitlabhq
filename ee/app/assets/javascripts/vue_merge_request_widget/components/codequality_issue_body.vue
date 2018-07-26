<script>
/**
 * Renders Code quality body text
 * Fixed: [name] in [link]:[line]
 */
import ReportLink from '~/vue_shared/components/reports/report_link.vue';
import { STATUS_SUCCESS } from '~/vue_shared/components/reports/constants';

export default {
  name: 'CodequalityIssueBody',

  components: {
    ReportLink,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isStatusSuccess() {
      return this.status === STATUS_SUCCESS;
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text">
      <template v-if="isStatusSuccess">{{ s__('ciReport|Fixed:') }}</template>

      {{ issue.name }}
    </div>

    <report-link
      v-if="issue.path"
      :issue="issue"
    />
  </div>
</template>
