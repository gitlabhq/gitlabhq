import { n__, s__ } from '~/locale';
import CEWidgetOptions from '~/vue_merge_request_widget/mr_widget_options';
import WidgetApprovals from './components/approvals/mr_widget_approvals';
import GeoSecondaryNode from './components/states/mr_widget_secondary_geo_node';
import RebaseState from './components/states/mr_widget_rebase.vue';
import collapsibleSection from './components/mr_widget_report_collapsible_section.vue';

export default {
  extends: CEWidgetOptions,
  components: {
    'mr-widget-approvals': WidgetApprovals,
    'mr-widget-geo-secondary-node': GeoSecondaryNode,
    'mr-widget-rebase': RebaseState,
    collapsibleSection,
  },
  data() {
    return {
      isLoadingCodequality: false,
      isLoadingPerformance: false,
      isLoadingSecurity: false,
      isLoadingDocker: false,
      loadingCodequalityFailed: false,
      loadingPerformanceFailed: false,
      loadingSecurityFailed: false,
      loadingDockerFailed: false,
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
      return this.mr.sast;
    },
    shouldRenderDockerReport() {
      return this.mr.clair;
    },
    codequalityText() {
      const { newIssues, resolvedIssues } = this.mr.codeclimateMetrics;
      const text = [];

      if (!newIssues.length && !resolvedIssues.length) {
        text.push('No changes to code quality');
      } else if (newIssues.length || resolvedIssues.length) {
        text.push('Code quality');

        if (resolvedIssues.length) {
          text.push(n__(
            ' improved on %d point',
            ' improved on %d points',
            resolvedIssues.length,
          ));
        }

        if (newIssues.length > 0 && resolvedIssues.length > 0) {
          text.push(' and');
        }

        if (newIssues.length) {
          text.push(n__(
            ' degraded on %d point',
            ' degraded on %d points',
            newIssues.length,
          ));
        }
      }

      return text.join('');
    },

    performanceText() {
      const { improved, degraded } = this.mr.performanceMetrics;
      const text = [];

      if (!improved.length && !degraded.length) {
        text.push('No changes to performance metrics');
      } else if (improved.length || degraded.length) {
        text.push('Performance metrics');

        if (improved.length) {
          text.push(n__(
            ' improved on %d point',
            ' improved on %d points',
            improved.length,
          ));
        }

        if (improved.length > 0 && degraded.length > 0) {
          text.push(' and');
        }

        if (degraded.length) {
          text.push(n__(
            ' degraded on %d point',
            ' degraded on %d points',
            degraded.length,
          ));
        }
      }

      return text.join('');
    },

    securityText() {
      if (this.mr.securityReport.length) {
        return n__(
          '%d security vulnerability detected',
          '%d security vulnerabilities detected',
          this.mr.securityReport.length,
        );
      }

      return 'No security vulnerabilities detected';
    },

    dockerText() {
      const { vulnerabilities, approved, unapproved } = this.mr.dockerReport;

      if (!vulnerabilities.length) {
        return s__('ciReport|No vulnerabilities were found');
      }

      if (!unapproved.length) {
        return n__(
          'Found %d approved vulnerability',
          'Found %d approved vulnerabilities',
          approved.length,
        );
      }

      if (unapproved.length && !approved.length) {
        return n__(
          'Found %d vulnerability',
          'Found %d vulnerabilities',
          unapproved.length,
        );
      }

      return `${n__(
        'Found %d vulnerability,',
        'Found %d vulnerabilities,',
        unapproved.length,
      )} ${n__(
        'of which %d is approved',
        'of which %d are approved',
        approved.length,
      )}`;
    },

    codequalityStatus() {
      return this.checkStatus(this.isLoadingCodequality, this.loadingCodequalityFailed);
    },

    performanceStatus() {
      return this.checkStatus(this.isLoadingPerformance, this.loadingPerformanceFailed);
    },

    securityStatus() {
      return this.checkStatus(this.isLoadingSecurity, this.loadingSecurityFailed);
    },

    dockerStatus() {
      return this.checkStatus(this.isLoadingDocker, this.loadingDockerFailed);
    },
  },
  methods: {
    checkStatus(loading, error) {
      if (loading) {
        return 'loading';
      } else if (error) {
        return 'error';
      }

      return 'success';
    },

    fetchCodeQuality() {
      const { head_path, head_blob_path, base_path, base_blob_path } = this.mr.codeclimate;

      this.isLoadingCodequality = true;

      Promise.all([
        this.service.fetchReport(head_path),
        this.service.fetchReport(base_path),
      ])
        .then((values) => {
          this.mr.compareCodeclimateMetrics(values[0], values[1], head_blob_path, base_blob_path);
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
        .then((values) => {
          this.mr.comparePerformanceMetrics(values[0], values[1]);
          this.isLoadingPerformance = false;
        })
        .catch(() => {
          this.isLoadingPerformance = false;
          this.loadingPerformanceFailed = true;
        });
    },

    fetchSecurity() {
      const { path, blob_path } = this.mr.sast;
      this.isLoadingSecurity = true;

      this.service.fetchReport(path)
        .then((data) => {
          this.mr.setSecurityReport(data, blob_path);
          this.isLoadingSecurity = false;
        })
        .catch(() => {
          this.isLoadingSecurity = false;
          this.loadingSecurityFailed = true;
        });
    },

    fetchDockerReport() {
      const { path } = this.mr.clair;
      this.isLoadingDocker = true;

      this.service.fetchReport(path)
        .then((data) => {
          this.mr.setDockerReport(data);
          this.isLoadingDocker = false;
        })
        .catch(() => {
          this.isLoadingDocker = false;
          this.loadingDockerFailed = true;
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
      <mr-widget-deployment
        v-if="shouldRenderDeployments"
        :mr="mr"
        :service="service"
        />
      <mr-widget-approvals
        v-if="shouldRenderApprovals"
        :mr="mr"
        :service="service"
        />
      <collapsible-section
        class="js-codequality-widget"
        v-if="shouldRenderCodeQuality"
        type="codequality"
        :status="codequalityStatus"
        loading-text="Loading codeclimate report"
        error-text="Failed to load codeclimate report"
        :success-text="codequalityText"
        :unresolvedIssues="mr.codeclimateMetrics.newIssues"
        :resolvedIssues="mr.codeclimateMetrics.resolvedIssues"
        />
      <collapsible-section
        class="js-performance-widget"
        v-if="shouldRenderPerformance"
        type="performance"
        :status="performanceStatus"
        loading-text="Loading performance report"
        error-text="Failed to load performance report"
        :success-text="performanceText"
        :unresolvedIssues="mr.performanceMetrics.degraded"
        :resolvedIssues="mr.performanceMetrics.improved"
        :neutralIssues="mr.performanceMetrics.neutral"
        />
      <collapsible-section
        class="js-sast-widget"
        v-if="shouldRenderSecurityReport"
        type="security"
        :status="securityStatus"
        loading-text="Loading security report"
        error-text="Failed to load security report"
        :success-text="securityText"
        :unresolvedIssues="mr.securityReport"
        />
      <collapsible-section
        class="js-docker-widget"
        v-if="shouldRenderDockerReport"
        type="codequality"
        :status="dockerStatus"
        loading-text="Loading clair report"
        error-text="Failed to load clair report"
        :success-text="dockerText"
        :unresolvedIssues="mr.dockerReport.unapproved"
        :resolvedIssues="mr.dockerReport.approved"
        />
      <div class="mr-widget-section">
        <component
          :is="componentName"
          :mr="mr"
          :service="service" />
        <mr-widget-related-links
          v-if="shouldRenderRelatedLinks"
          :related-links="mr.relatedLinks"
          />
      </div>
      <div class="mr-widget-footer" v-if="shouldRenderMergeHelp">
        <mr-widget-merge-help />
      </div>
    </div>
  `,
};
