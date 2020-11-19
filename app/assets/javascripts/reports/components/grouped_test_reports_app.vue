<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { once } from 'lodash';
import { GlButton } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { componentNames } from './issue_body';
import ReportSection from './report_section.vue';
import SummaryRow from './summary_row.vue';
import IssuesList from './issues_list.vue';
import Modal from './modal.vue';
import createStore from '../store';
import Tracking from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  summaryTextBuilder,
  reportTextBuilder,
  statusIcon,
  recentFailuresTextBuilder,
} from '../store/utils';

export default {
  name: 'GroupedTestReportsApp',
  store: createStore(),
  components: {
    ReportSection,
    SummaryRow,
    IssuesList,
    Modal,
    GlButton,
  },
  mixins: [glFeatureFlagsMixin(), Tracking.mixin()],
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
  },
  componentNames,
  computed: {
    ...mapState(['reports', 'isLoading', 'hasError', 'summary']),
    ...mapState({
      modalTitle: state => state.modal.title || '',
      modalData: state => state.modal.data || {},
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
    handleToggleEvent() {
      return once(() => {
        this.track(this.$options.expandEvent);
      });
    },
  },
  created() {
    this.setEndpoint(this.endpoint);

    this.fetchReports();
  },
  methods: {
    ...mapActions(['setEndpoint', 'fetchReports']),
    reportText(report) {
      const { name, summary } = report || {};

      if (report.status === 'error') {
        return sprintf(s__('Reports|An error occurred while loading %{name} results'), { name });
      }

      if (!report.name) {
        return s__('Reports|An error occured while loading report');
      }

      return reportTextBuilder(name, summary);
    },
    hasRecentFailures(summary) {
      return this.glFeatures.testFailureHistory && summary?.recentlyFailed > 0;
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
      return report.existing_failures.concat(report.existing_errors);
    },
    newIssues(report) {
      return report.new_failures.concat(report.new_errors);
    },
    resolvedIssues(report) {
      return report.resolved_failures.concat(report.resolved_errors);
    },
  },
  expandEvent: 'expand_test_report_widget',
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
    @toggleEvent="handleToggleEvent"
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
          <summary-row :key="`summary-row-${i}`" :status-icon="getReportIcon(report)">
            <template #summary>
              <div class="gl-display-inline-flex gl-flex-direction-column">
                <div>{{ reportText(report) }}</div>
                <div v-if="hasRecentFailures(report.summary)">
                  {{ recentFailuresText(report.summary) }}
                </div>
              </div>
            </template>
          </summary-row>
          <issues-list
            v-if="shouldRenderIssuesList(report)"
            :key="`issues-list-${i}`"
            :unresolved-issues="unresolvedIssues(report)"
            :new-issues="newIssues(report)"
            :resolved-issues="resolvedIssues(report)"
            :component="$options.componentNames.TestIssueBody"
            class="report-block-group-list"
          />
        </template>

        <modal :title="modalTitle" :modal-data="modalData" />
      </div>
    </template>
  </report-section>
</template>
