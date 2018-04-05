import { n__, s__, __, sprintf } from '~/locale';
import CEWidgetOptions from '~/vue_merge_request_widget/mr_widget_options';
import WidgetApprovals from './components/approvals/mr_widget_approvals';
import GeoSecondaryNode from './components/states/mr_widget_secondary_geo_node';
import ReportSection from '../vue_shared/security_reports/components/report_section.vue';
import GroupedSecurityReportsApp from '../vue_shared/security_reports/grouped_security_reports_app.vue';
import reportsMixin from '../vue_shared/security_reports/mixins/reports_mixin';

export default {
  extends: CEWidgetOptions,
  components: {
    'mr-widget-approvals': WidgetApprovals,
    'mr-widget-geo-secondary-node': GeoSecondaryNode,
    GroupedSecurityReportsApp,
    ReportSection,
  },
  mixins: [reportsMixin],
  data() {
    return {
      isLoadingCodequality: false,
      isLoadingPerformance: false,
      loadingCodequalityFailed: false,
      loadingPerformanceFailed: false,
    };
  },
  computed: {
    shouldRenderApprovals() {
      return this.mr.approvalsRequired && this.mr.state !== 'nothingToMerge';
    },
    shouldRenderCodeQuality() {
      const { codeclimate } = this.mr;
      return codeclimate && codeclimate.head_path && codeclimate.base_path;
    },
    hasCodequalityIssues() {
      return (
        this.mr.codeclimateMetrics &&
        ((this.mr.codeclimateMetrics.newIssues &&
          this.mr.codeclimateMetrics.newIssues.length > 0) ||
          (this.mr.codeclimateMetrics.resolvedIssues &&
            this.mr.codeclimateMetrics.resolvedIssues.length > 0))
      );
    },
    hasPerformanceMetrics() {
      return (
        this.mr.performanceMetrics &&
        ((this.mr.performanceMetrics.degraded && this.mr.performanceMetrics.degraded.length > 0) ||
          (this.mr.performanceMetrics.improved && this.mr.performanceMetrics.improved.length > 0) ||
          (this.mr.performanceMetrics.neutral && this.mr.performanceMetrics.neutral.length > 0))
      );
    },
    shouldRenderPerformance() {
      const { performance } = this.mr;
      return performance && performance.head_path && performance.base_path;
    },
    shouldRenderSecurityReport() {
      return (
        (this.mr.sast && this.mr.sast.head_path) ||
        (this.mr.sastContainer && this.mr.sastContainer.head_path) ||
        (this.mr.dast && this.mr.dast.head_path) ||
        (this.mr.dependencyScanning && this.mr.dependencyScanning.head_path)
      );
    },
    codequalityText() {
      const { newIssues, resolvedIssues } = this.mr.codeclimateMetrics;
      const text = [];

      if (!newIssues.length && !resolvedIssues.length) {
        text.push(s__('ciReport|No changes to code quality'));
      } else if (newIssues.length || resolvedIssues.length) {
        text.push(s__('ciReport|Code quality'));

        if (resolvedIssues.length) {
          text.push(n__(' improved on %d point', ' improved on %d points', resolvedIssues.length));
        }

        if (newIssues.length > 0 && resolvedIssues.length > 0) {
          text.push(__(' and'));
        }

        if (newIssues.length) {
          text.push(n__(' degraded on %d point', ' degraded on %d points', newIssues.length));
        }
      }

      return text.join('');
    },

    performanceText() {
      const { improved, degraded } = this.mr.performanceMetrics;
      const text = [];

      if (!improved.length && !degraded.length) {
        text.push(s__('ciReport|No changes to performance metrics'));
      } else if (improved.length || degraded.length) {
        text.push(s__('ciReport|Performance metrics'));

        if (improved.length) {
          text.push(n__(' improved on %d point', ' improved on %d points', improved.length));
        }

        if (improved.length > 0 && degraded.length > 0) {
          text.push(__(' and'));
        }

        if (degraded.length) {
          text.push(n__(' degraded on %d point', ' degraded on %d points', degraded.length));
        }
      }

      return text.join('');
    },

    codequalityStatus() {
      return this.checkReportStatus(this.isLoadingCodequality, this.loadingCodequalityFailed);
    },

    performanceStatus() {
      return this.checkReportStatus(this.isLoadingPerformance, this.loadingPerformanceFailed);
    },
  },
  methods: {
    fetchCodeQuality() {
      const { head_path, base_path } = this.mr.codeclimate;

      this.isLoadingCodequality = true;

      Promise.all([this.service.fetchReport(head_path), this.service.fetchReport(base_path)])
        .then(values => {
          this.mr.compareCodeclimateMetrics(
            values[0],
            values[1],
            this.mr.headBlobPath,
            this.mr.baseBlobPath,
          );
          this.isLoadingCodequality = false;
        })
        .catch(() => {
          this.isLoadingCodequality = false;
          this.loadingCodequalityFailed = true;
        });
    },

    fetchPerformance() {
      const { head_path, base_path } = this.mr.performance;

      this.isLoadingPerformance = true;

      Promise.all([this.service.fetchReport(head_path), this.service.fetchReport(base_path)])
        .then(values => {
          this.mr.comparePerformanceMetrics(values[0], values[1]);
          this.isLoadingPerformance = false;
        })
        .catch(() => {
          this.isLoadingPerformance = false;
          this.loadingPerformanceFailed = true;
        });
    },

    translateText(type) {
      return {
        error: sprintf(s__('ciReport|Failed to load %{reportName} report'), {
          reportName: type,
        }),
        loading: sprintf(s__('ciReport|Loading %{reportName} report'), {
          reportName: type,
        }),
      };
    },
  },
  created() {
    if (this.shouldRenderCodeQuality) {
      this.fetchCodeQuality();
    }

    if (this.shouldRenderPerformance) {
      this.fetchPerformance();
    }
  },
  template: `
    <div class="mr-state-widget prepend-top-default">
      <mr-widget-header :mr="mr" />
      <mr-widget-pipeline
        v-if="shouldRenderPipelines"
        :pipeline="mr.pipeline"
        :ci-status="mr.ciStatus"
        :has-ci="mr.hasCI"
        />
      <deployment
        v-for="deployment in mr.deployments"
        :key="deployment.id"
        :deployment="deployment"
      />
      <mr-widget-approvals
        v-if="shouldRenderApprovals"
        :mr="mr"
        :service="service"
      />
      <report-section
        class="js-codequality-widget"
        v-if="shouldRenderCodeQuality"
        type="codequality"
        :status="codequalityStatus"
        :loading-text="translateText('codeclimate').loading"
        :error-text="translateText('codeclimate').error"
        :success-text="codequalityText"
        :unresolved-issues="mr.codeclimateMetrics.newIssues"
        :resolved-issues="mr.codeclimateMetrics.resolvedIssues"
        :has-issues="hasCodequalityIssues"
      />
      <report-section
        class="js-performance-widget"
        v-if="shouldRenderPerformance"
        type="performance"
        :status="performanceStatus"
        :loading-text="translateText('performance').loading"
        :error-text="translateText('performance').error"
        :success-text="performanceText"
        :unresolved-issues="mr.performanceMetrics.degraded"
        :resolved-issues="mr.performanceMetrics.improved"
        :neutral-issues="mr.performanceMetrics.neutral"
        :has-issues="hasPerformanceMetrics"
      />
      <grouped-security-reports-app
        v-if="shouldRenderSecurityReport"
        :head-blob-path="mr.headBlobPath"
        :base-blob-path="mr.baseBlobPath"
        :sast-head-path="mr.sast.head_path"
        :sast-base-path="mr.sast.base_path"
        :sast-help-path="mr.sastHelp"
        :dast-head-path="mr.dast.head_path"
        :dast-base-path="mr.dast.base_path"
        :dast-help-path="mr.dastHelp"
        :sast-container-head-path="mr.sastContainer.head_path"
        :sast-container-base-path="mr.sastContainer.base_path"
        :sast-container-help-path="mr.sastContainerHelp"
        :dependency-scanning-head-path="mr.dependencyScanning.head_path"
        :dependency-scanning-base-path="mr.dependencyScanning.base_path"
        :dependency-scanning-help-path="mr.dependencyScanningHelp"
      />
      <div class="mr-widget-section">
        <component
          :is="componentName"
          :mr="mr"
          :service="service" />
        <mr-widget-maintainer-edit
          :maintainerEditAllowed="mr.maintainerEditAllowed" />
        <mr-widget-related-links
          v-if="shouldRenderRelatedLinks"
          :state="mr.state"
          :related-links="mr.relatedLinks" />
        <source-branch-removal-status
          v-if="shouldRenderSourceBranchRemovalStatus"
        />
      </div>
      <div class="mr-widget-footer" v-if="shouldRenderMergeHelp">
        <mr-widget-merge-help />
      </div>
    </div>
  `,
};
