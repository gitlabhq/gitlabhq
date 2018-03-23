import { n__, s__, __ } from '~/locale';
import CEWidgetOptions from '~/vue_merge_request_widget/mr_widget_options';
import WidgetApprovals from './components/approvals/mr_widget_approvals';
import GeoSecondaryNode from './components/states/mr_widget_secondary_geo_node';
import ReportSection from '../vue_shared/security_reports/components/report_section.vue';
import securityMixin from '../vue_shared/security_reports/mixins/security_report_mixin';
import {
  SAST,
  DAST,
  SAST_CONTAINER,
} from '../vue_shared/security_reports/helpers/constants';

export default {
  extends: CEWidgetOptions,
  components: {
    'mr-widget-approvals': WidgetApprovals,
    'mr-widget-geo-secondary-node': GeoSecondaryNode,
    ReportSection,
  },
  mixins: [securityMixin],
  dast: DAST,
  sast: SAST,
  sastContainer: SAST_CONTAINER,
  data() {
    return {
      isLoadingCodequality: false,
      isLoadingPerformance: false,
      isLoadingSecurity: false,
      isLoadingDocker: false,
      isLoadingDast: false,
      isLoadingDependencyScanning: false,
      loadingCodequalityFailed: false,
      loadingPerformanceFailed: false,
      loadingSecurityFailed: false,
      loadingDockerFailed: false,
      loadingDastFailed: false,
      loadingDependencyScanningFailed: false,
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
    shouldRenderPerformance() {
      const { performance } = this.mr;
      return performance && performance.head_path && performance.base_path;
    },
    shouldRenderSecurityReport() {
      return this.mr.sast && this.mr.sast.head_path;
    },
    shouldRenderDockerReport() {
      return this.mr.sastContainer && this.mr.sastContainer.head_path;
    },
    shouldRenderDastReport() {
      return this.mr.dast && this.mr.dast.head_path;
    },
    shouldRenderDependencyReport() {
      return this.mr.dependencyScanning && this.mr.dependencyScanning.head_path;
    },
    codequalityText() {
      const { newIssues, resolvedIssues } = this.mr.codeclimateMetrics;
      const text = [];

      if (!newIssues.length && !resolvedIssues.length) {
        text.push(s__('ciReport|No changes to code quality'));
      } else if (newIssues.length || resolvedIssues.length) {
        text.push(s__('ciReport|Code quality'));

        if (resolvedIssues.length) {
          text.push(
            n__(
              ' improved on %d point',
              ' improved on %d points',
              resolvedIssues.length,
            ),
          );
        }

        if (newIssues.length > 0 && resolvedIssues.length > 0) {
          text.push(__(' and'));
        }

        if (newIssues.length) {
          text.push(
            n__(
              ' degraded on %d point',
              ' degraded on %d points',
              newIssues.length,
            ),
          );
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
          text.push(
            n__(
              ' improved on %d point',
              ' improved on %d points',
              improved.length,
            ),
          );
        }

        if (improved.length > 0 && degraded.length > 0) {
          text.push(__(' and'));
        }

        if (degraded.length) {
          text.push(
            n__(
              ' degraded on %d point',
              ' degraded on %d points',
              degraded.length,
            ),
          );
        }
      }

      return text.join('');
    },

    securityText() {
      const { newIssues, resolvedIssues, allIssues } = this.mr.securityReport;
      return this.sastText(newIssues, resolvedIssues, allIssues);
    },

    dependencyScanningText() {
      const { newIssues, resolvedIssues, allIssues } = this.mr.dependencyScanningReport;
      return this.depedencyScanningText(newIssues, resolvedIssues, allIssues);
    },

    dockerText() {
      const { vulnerabilities, approved, unapproved } = this.mr.dockerReport;
      return this.sastContainerText(vulnerabilities, approved, unapproved);
    },

    getDastText() {
      return this.dastText(this.mr.dastReport);
    },

    codequalityStatus() {
      return this.checkReportStatus(
        this.isLoadingCodequality,
        this.loadingCodequalityFailed,
      );
    },

    performanceStatus() {
      return this.checkReportStatus(
        this.isLoadingPerformance,
        this.loadingPerformanceFailed,
      );
    },

    securityStatus() {
      return this.checkReportStatus(
        this.isLoadingSecurity,
        this.loadingSecurityFailed,
      );
    },

    dockerStatus() {
      return this.checkReportStatus(
        this.isLoadingDocker,
        this.loadingDockerFailed,
      );
    },

    dastStatus() {
      return this.checkReportStatus(this.isLoadingDast, this.loadingDastFailed);
    },

    dependencyScanningStatus() {
      return this.checkReportStatus(
        this.isLoadingDependencyScanning,
        this.loadingDependencyScanningFailed,
      );
    },
  },
  methods: {
    fetchCodeQuality() {
      const { head_path, base_path } = this.mr.codeclimate;

      this.isLoadingCodequality = true;

      Promise.all([
        this.service.fetchReport(head_path),
        this.service.fetchReport(base_path),
      ])
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

      Promise.all([
        this.service.fetchReport(head_path),
        this.service.fetchReport(base_path),
      ])
        .then(values => {
          this.mr.comparePerformanceMetrics(values[0], values[1]);
          this.isLoadingPerformance = false;
        })
        .catch(() => {
          this.isLoadingPerformance = false;
          this.loadingPerformanceFailed = true;
        });
    },
    /**
     * Sast report can either have 2 reports or just 1
     * When it has 2 we need to compare them
     * When it has 1 we render the output given
     */
    fetchSecurity() {
      const { sast } = this.mr;

      this.isLoadingSecurity = true;

      if (sast.base_path && sast.head_path) {
        Promise.all([
          this.service.fetchReport(sast.head_path),
          this.service.fetchReport(sast.base_path),
        ])
          .then(values => {
            this.handleSecuritySuccess({
              head: values[0],
              headBlobPath: this.mr.headBlobPath,
              base: values[1],
              baseBlobPath: this.mr.baseBlobPath,
            });
          })
          .catch(() => this.handleSecurityError());
      } else if (sast.head_path) {
        this.service
          .fetchReport(sast.head_path)
          .then(data => {
            this.handleSecuritySuccess({
              head: data,
              headBlobPath: this.mr.headBlobPath,
            });
          })
          .catch(() => this.handleSecurityError());
      }
    },

    fetchDependencyScanning() {
      const { dependencyScanning } = this.mr;

      this.isLoadingDependencyScanning = true;

      if (dependencyScanning.base_path && dependencyScanning.head_path) {
        Promise.all([
          this.service.fetchReport(dependencyScanning.head_path),
          this.service.fetchReport(dependencyScanning.base_path),
        ])
          .then(values => {
            this.mr.setDependencyScanningReport({
              head: values[0],
              headBlobPath: this.mr.headBlobPath,
              base: values[1],
              baseBlobPath: this.mr.baseBlobPath,
            });
            this.isLoadingDependencyScanning = false;
          })
          .catch(() => {
            this.isLoadingDependencyScanning = false;
            this.loadingDependencyScanningFailed = true;
          });
      } else if (dependencyScanning.head_path) {
        this.service
          .fetchReport(dependencyScanning.head_path)
          .then(data => {
            this.mr.setDependencyScanningReport({
              head: data,
              headBlobPath: this.mr.headBlobPath,
            });
            this.isLoadingDependencyScanning = false;
          })
          .catch(() => {
            this.isLoadingDependencyScanning = false;
            this.loadingDependencyScanningFailed = true;
          });
      }
    },

    handleSecuritySuccess(data) {
      this.mr.setSecurityReport(data);
      this.isLoadingSecurity = false;
    },

    handleSecurityError() {
      this.isLoadingSecurity = false;
      this.loadingSecurityFailed = true;
    },

    fetchDockerReport() {
      const { head_path } = this.mr.sastContainer;
      this.isLoadingDocker = true;

      this.service
        .fetchReport(head_path)
        .then(data => {
          this.mr.setDockerReport(data);
          this.isLoadingDocker = false;
        })
        .catch(() => {
          this.isLoadingDocker = false;
          this.loadingDockerFailed = true;
        });
    },

    fetchDastReport() {
      this.isLoadingDast = true;

      this.service
        .fetchReport(this.mr.dast.head_path)
        .then(data => {
          this.mr.setDastReport(data);
          this.isLoadingDast = false;
        })
        .catch(() => {
          this.isLoadingDast = false;
          this.loadingDastFailed = true;
        });
    },
  },
  created() {
    if (this.shouldRenderCodeQuality) {
      this.fetchCodeQuality();
    }

    if (this.shouldRenderPerformance) {
      this.fetchPerformance();
    }

    if (this.shouldRenderSecurityReport) {
      this.fetchSecurity();
    }

    if (this.shouldRenderDockerReport) {
      this.fetchDockerReport();
    }

    if (this.shouldRenderDastReport) {
      this.fetchDastReport();
    }

    if (this.shouldRenderDependencyReport) {
      this.fetchDependencyScanning();
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
      />
      <report-section
        class="js-sast-widget"
        v-if="shouldRenderSecurityReport"
        :type="$options.sast"
        :status="securityStatus"
        :loading-text="translateText('security').loading"
        :error-text="translateText('security').error"
        :success-text="securityText"
        :unresolved-issues="mr.securityReport.newIssues"
        :resolved-issues="mr.securityReport.resolvedIssues"
        :all-issues="mr.securityReport.allIssues"
        />
      <report-section
        class="js-dependency-scanning-widget"
        v-if="shouldRenderDependencyReport"
        :type="$options.sast"
        :status="dependencyScanningStatus"
        :loading-text="translateText('dependency scanning').loading"
        :error-text="translateText('dependency scanning').error"
        :success-text="dependencyScanningText"
        :unresolved-issues="mr.dependencyScanningReport.newIssues"
        :resolved-issues="mr.dependencyScanningReport.resolvedIssues"
        :all-issues="mr.dependencyScanningReport.allIssues"
      />
      <report-section
        class="js-docker-widget"
        v-if="shouldRenderDockerReport"
        :type="$options.sastContainer"
        :status="dockerStatus"
        :loading-text="translateText('sast:container').loading"
        :error-text="translateText('sast:container').error"
        :success-text="dockerText"
        :unresolved-issues="mr.dockerReport.unapproved"
        :neutral-issues="mr.dockerReport.approved"
        :info-text="sastContainerInformationText()"
      />
      <report-section
        class="js-dast-widget"
        v-if="shouldRenderDastReport"
        :type="$options.dast"
        :status="dastStatus"
        :loading-text="translateText('DAST').loading"
        :error-text="translateText('DAST').error"
        :success-text="getDastText"
        :unresolved-issues="mr.dastReport"
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
