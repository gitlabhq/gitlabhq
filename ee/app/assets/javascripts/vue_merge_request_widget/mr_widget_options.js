import { n__, s__, sprintf } from '~/locale';
import CEWidgetOptions from '~/vue_merge_request_widget/mr_widget_options';
import WidgetApprovals from './components/approvals/mr_widget_approvals';
import GeoSecondaryNode from './components/states/mr_widget_secondary_geo_node';
import collapsibleSection from './components/mr_widget_report_collapsible_section.vue';

export default {
  extends: CEWidgetOptions,
  components: {
    'mr-widget-approvals': WidgetApprovals,
    'mr-widget-geo-secondary-node': GeoSecondaryNode,
    collapsibleSection,
  },
  data() {
    return {
      isLoadingCodequality: false,
      isLoadingPerformance: false,
      isLoadingSecurity: false,
      isLoadingDocker: false,
      isLoadingDast: false,
      loadingCodequalityFailed: false,
      loadingPerformanceFailed: false,
      loadingSecurityFailed: false,
      loadingDockerFailed: false,
      loadingDastFailed: false,
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
      return this.mr.sastContainer;
    },
    shouldRenderDastReport() {
      return this.mr.dast;
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

      if (!unapproved.length && approved.length) {
        return n__(
          'Found %d approved vulnerability',
          'Found %d approved vulnerabilities',
          approved.length,
        );
      } else if (unapproved.length && !approved.length) {
        return n__(
          'Found %d vulnerability',
          'Found %d vulnerabilities',
          unapproved.length,
        );
      }

      return `${n__(
        'Found %d vulnerability,',
        'Found %d vulnerabilities,',
        vulnerabilities.length,
      )} ${n__(
        'of which %d is approved',
        'of which %d are approved',
        approved.length,
      )}`;
    },

    dastText() {
      if (this.mr.dastReport.length) {
        return n__(
          '%d DAST alert detected by analyzing the review app',
          '%d DAST alerts detected by analyzing the review app',
          this.mr.dastReport.length,
        );
      }

      return s__('ciReport|No DAST alerts detected by analyzing the review app');
    },

    codequalityStatus() {
      return this.checkReportStatus(this.isLoadingCodequality, this.loadingCodequalityFailed);
    },

    performanceStatus() {
      return this.checkReportStatus(this.isLoadingPerformance, this.loadingPerformanceFailed);
    },

    securityStatus() {
      return this.checkReportStatus(this.isLoadingSecurity, this.loadingSecurityFailed);
    },

    dockerStatus() {
      return this.checkReportStatus(this.isLoadingDocker, this.loadingDockerFailed);
    },

    dastStatus() {
      return this.checkReportStatus(this.isLoadingDast, this.loadingDastFailed);
    },

    dockerInformationText() {
      return sprintf(
        s__('ciReport|Unapproved vulnerabilities (red) can be marked as approved. %{helpLink}'), {
          helpLink: `<a href="https://gitlab.com/gitlab-org/clair-scanner#example-whitelist-yaml-file" target="_blank" rel="noopener noreferrer nofollow">
            ${s__('ciReport|Learn more about whitelisting')}
          </a>`,
        },
        false,
      );
    },
  },
  methods: {
    checkReportStatus(loading, error) {
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
      const { path } = this.mr.sastContainer;
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

    fetchDastReport() {
      this.isLoadingDast = true;

      this.service.fetchReport(this.mr.dast.path)
        .then((data) => {
          this.mr.setDastReport(data);
          this.isLoadingDast = false;
        })
        .catch(() => {
          this.isLoadingDast = false;
          this.loadingDastFailed = true;
        });
    },

    translateText(type) {
      return {
        error: s__(`ciReport|Failed to load ${type} report`),
        loading: s__(`ciReport|Loading ${type} report`),
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

    if (this.shouldRenderSecurityReport) {
      this.fetchSecurity();
    }

    if (this.shouldRenderDockerReport) {
      this.fetchDockerReport();
    }

    if (this.shouldRenderDastReport) {
      this.fetchDastReport();
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
        :loading-text="translateText('codeclimate').loading"
        :error-text="translateText('codeclimate').error"
        :success-text="codequalityText"
        :unresolved-issues="mr.codeclimateMetrics.newIssues"
        :resolved-issues="mr.codeclimateMetrics.resolvedIssues"
        />
      <collapsible-section
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
      <collapsible-section
        class="js-sast-widget"
        v-if="shouldRenderSecurityReport"
        type="security"
        :status="securityStatus"
        :loading-text="translateText('security').loading"
        :error-text="translateText('security').error"
        :success-text="securityText"
        :unresolved-issues="mr.securityReport"
        :has-priority="true"
        />
      <collapsible-section
        class="js-docker-widget"
        v-if="shouldRenderDockerReport"
        type="docker"
        :status="dockerStatus"
        :loading-text="translateText('sast:container').loading"
        :error-text="translateText('sast:container').error"
        :success-text="dockerText"
        :unresolved-issues="mr.dockerReport.unapproved"
        :neutral-issues="mr.dockerReport.approved"
        :info-text="dockerInformationText"
        :has-priority="true"
        />
      <collapsible-section
        class="js-dast-widget"
        v-if="shouldRenderDastReport"
        type="dast"
        :status="dastStatus"
        :loading-text="translateText('DAST').loading"
        :error-text="translateText('DAST').error"
        :success-text="dastText"
        :unresolved-issues="mr.dastReport"
        :has-priority="true"
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
