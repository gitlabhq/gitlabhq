<script>
  /**
   * Renders Perfomance issue body text
   *  [name] :[score] [symbol] [delta] in [link]
   */
  import ReportLink from 'ee/vue_shared/security_reports/components/report_link.vue';

  export default {
    name: 'PerformanceIssueBody',

    components: {
      ReportLink,
    },

    props: {
      issue: {
        type: Object,
        required: true,
      },
    },

    methods: {
      formatScore(value) {
        if (Math.floor(value) !== value) {
          return parseFloat(value).toFixed(2);
        }
        return value;
      },
    },
  };
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text append-right-5">
      {{ issue.name }}<template v-if="issue.score">:
      <strong>{{ formatScore(issue.score) }}</strong></template>

      <template v-if="issue.delta != null">
        ({{ issue.delta >= 0 ? '+' : '' }}{{ formatScore(issue.delta) }})
      </template>
    </div>

    <report-link
      v-if="issue.path"
      :issue="issue"
    />
  </div>
</template>
