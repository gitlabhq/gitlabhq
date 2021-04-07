<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import api from '~/api';
import { sprintf, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import GroupedIssuesList from '../components/grouped_issues_list.vue';
import { componentNames } from '../components/issue_body';
import ReportSection from '../components/report_section.vue';
import SummaryRow from '../components/summary_row.vue';
import Modal from './components/modal.vue';
import createStore from './store';
import {
  summaryTextBuilder,
  reportTextBuilder,
  statusIcon,
  recentFailuresTextBuilder,
} from './store/utils';

export default {
  name: 'GroupedTestReportsApp',
  store: createStore(),
  components: {
    ReportSection,
    SummaryRow,
    GroupedIssuesList,
    Modal,
    GlButton,
    GlIcon,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    pipelinePath: {
      type: String,
      required: false,
      default: '',
    },
    headBlobPath: {
      type: String,
      required: true,
    },
  },
  componentNames,
  computed: {
    ...mapState(['reports', 'isLoading', 'hasError', 'summary']),
    ...mapState({
      modalTitle: (state) => state.modal.title || '',
      modalData: (state) => state.modal.data || {},
      modalOpen: (state) => state.modal.open || false,
    }),
    ...mapGetters(['summaryStatus']),
    groupedSummaryText() {
      if (this.isLoading) {
        return s__('Reports|Test summary results are being parsed');
      }

      if (this.hasError) {
        return s__('Reports|Test summary failed loading results');
      }

      return summaryTextBuilder(s__('Reports|Test summary'), this.summary);
    },
    testTabURL() {
      return `${this.pipelinePath}/test_report`;
    },
    showViewFullReport() {
      return this.pipelinePath.length;
    },
  },
  created() {
    this.setPaths({
      endpoint: this.endpoint,
      headBlobPath: this.headBlobPath,
    });

    this.fetchReports();
  },
  methods: {
    ...mapActions(['setPaths', 'fetchReports', 'closeModal']),
    handleToggleEvent() {
      if (this.glFeatures.usageDataITestingSummaryWidgetTotal) {
        api.trackRedisHllUserEvent(this.$options.expandEvent);
      }
    },
    reportText(report) {
      const { name, summary } = report || {};

      if (report.status === 'error') {
        return sprintf(s__('Reports|An error occurred while loading %{name} results'), { name });
      }

      if (!report.name) {
        return s__('Reports|An error occurred while loading report');
      }

      return reportTextBuilder(name, summary);
    },
    hasRecentFailures(summary) {
      return summary?.recentlyFailed > 0;
    },
    recentFailuresText(summary) {
      return recentFailuresTextBuilder(summary);
    },
    getReportIcon(report) {
      return statusIcon(report.status);
    },
    shouldRenderIssuesList(report) {
      return (
        report.existing_failures.length > 0 ||
        report.new_failures.length > 0 ||
        report.resolved_failures.length > 0 ||
        report.existing_errors.length > 0 ||
        report.new_errors.length > 0 ||
        report.resolved_errors.length > 0
      );
    },
    unresolvedIssues(report) {
      return [
        ...report.new_failures,
        ...report.new_errors,
        ...report.existing_failures,
        ...report.existing_errors,
      ];
    },
    resolvedIssues(report) {
      return report.resolved_failures.concat(report.resolved_errors);
    },
  },
  expandEvent: 'i_testing_summary_widget_total',
};
</script>
<template>
  <report-section
    :status="summaryStatus"
    :success-text="groupedSummaryText"
    :loading-text="groupedSummaryText"
    :error-text="groupedSummaryText"
    :has-issues="reports.length > 0"
    :should-emit-toggle-event="true"
    class="mr-widget-section grouped-security-reports mr-report"
    @toggleEvent.once="handleToggleEvent"
  >
    <template v-if="showViewFullReport" #action-buttons>
      <gl-button
        :href="testTabURL"
        target="_blank"
        icon="external-link"
        data-testid="group-test-reports-full-link"
        class="gl-mr-3"
      >
        {{ s__('ciReport|View full report') }}
      </gl-button>
    </template>
    <template v-if="hasRecentFailures(summary)" #sub-heading>
      {{ recentFailuresText(summary) }}
    </template>
    <template #body>
      <div class="mr-widget-grouped-section report-block">
        <template v-for="(report, i) in reports">
          <summary-row
            :key="`summary-row-${i}`"
            :status-icon="getReportIcon(report)"
            nested-summary
          >
            <template #summary>
              <div class="gl-display-inline-flex gl-flex-direction-column">
                <div>{{ reportText(report) }}</div>
                <div v-if="report.suite_errors">
                  <div v-if="report.suite_errors.head">
                    <gl-icon name="warning" class="gl-mx-2 gl-text-orange-500" />
                    {{ s__('Reports|Head report parsing error:') }}
                    {{ report.suite_errors.head }}
                  </div>
                  <div v-if="report.suite_errors.base">
                    <gl-icon name="warning" class="gl-mx-2 gl-text-orange-500" />
                    {{ s__('Reports|Base report parsing error:') }}
                    {{ report.suite_errors.base }}
                  </div>
                </div>
                <div v-if="hasRecentFailures(report.summary)">
                  {{ recentFailuresText(report.summary) }}
                </div>
              </div>
            </template>
          </summary-row>
          <grouped-issues-list
            v-if="shouldRenderIssuesList(report)"
            :key="`issues-list-${i}`"
            :unresolved-issues="unresolvedIssues(report)"
            :resolved-issues="resolvedIssues(report)"
            :component="$options.componentNames.TestIssueBody"
            :nested-level="2"
          />
        </template>
        <modal
          :visible="modalOpen"
          :title="modalTitle"
          :modal-data="modalData"
          @hide="closeModal"
        />
      </div>
    </template>
  </report-section>
</template>
