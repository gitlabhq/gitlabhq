<script>
  /**
   * Renders Code quality body text
   * Fixed: [name] in [link]:[line]
   */
  import ReportLink from 'ee/vue_shared/security_reports/components/report_link.vue';

  export default {
    name: 'CodequalityIssueBody',

    components: {
      ReportLink,
    },

    props: {
      isStatusSuccess: {
        type: Boolean,
        required: true,
      },
      issue: {
        type: Object,
        required: true,
      },
    },
  };
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text append-right-5">
      <template v-if="isStatusSuccess">{{ s__('ciReport|Fixed:') }}</template>

      {{ issue.name }}
    </div>

    <report-link
      v-if="issue.path"
      :issue="issue"
    />
  </div>
</template>
