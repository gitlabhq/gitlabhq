<script>
import { mapActions, mapGetters } from 'vuex';
import { componentNames } from '~/reports/components/issue_body';
import IssuesList from '~/reports/components/issues_list.vue';
import ReportSection from '~/reports/components/report_section.vue';
import createStore from './store';

export default {
  name: 'GroupedAccessibilityReportsApp',
  store: createStore(),
  components: {
    ReportSection,
    IssuesList,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  componentNames,
  computed: {
    ...mapGetters([
      'summaryStatus',
      'groupedSummaryText',
      'shouldRenderIssuesList',
      'unresolvedIssues',
      'resolvedIssues',
      'newIssues',
    ]),
  },
  created() {
    this.setEndpoint(this.endpoint);

    this.fetchReport();
  },
  methods: {
    ...mapActions(['fetchReport', 'setEndpoint']),
  },
};
</script>
<template>
  <report-section
    :status="summaryStatus"
    :success-text="groupedSummaryText"
    :loading-text="groupedSummaryText"
    :error-text="groupedSummaryText"
    :has-issues="shouldRenderIssuesList"
    track-action="users_expanding_testing_accessibility_report"
    class="mr-widget-section grouped-security-reports mr-report"
  >
    <template #body>
      <div class="mr-widget-grouped-section report-block">
        <issues-list
          v-if="shouldRenderIssuesList"
          :unresolved-issues="unresolvedIssues"
          :new-issues="newIssues"
          :resolved-issues="resolvedIssues"
          :component="$options.componentNames.AccessibilityIssueBody"
          class="report-block-group-list"
        />
      </div>
    </template>
  </report-section>
</template>
