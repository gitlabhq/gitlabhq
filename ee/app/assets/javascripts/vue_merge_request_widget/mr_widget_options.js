import { n__ } from '~/locale';
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
      isLoadingSecurity: false,
      loadingCodequalityFailed: false,
      loadingSecurityFailed: false,
    };
  },
  computed: {
    shouldRenderApprovals() {
      return this.mr.approvalsRequired;
    },
    shouldRenderCodeQuality() {
      const { codeclimate } = this.mr;
      return codeclimate && codeclimate.head_path && codeclimate.base_path;
    },
    shouldRenderSecurityReport() {
      return this.mr.security && this.mr.security.sast;
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

    codequalityStatus() {
      if (this.isLoadingCodequality) {
        return 'loading';
      } else if (this.loadingCodequalityFailed) {
        return 'error';
      }
      return 'success';
    },

    securityStatus() {
      if (this.isLoadingSecurity) {
        return 'loading';
      } else if (this.loadingSecurityFailed) {
        return 'error';
      }
      return 'success';
    },
  },
  methods: {
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

    fetchSecurity() {
      const { path, blob_path } = this.mr.security.sast;
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
  },
  created() {
    if (this.shouldRenderCodeQuality) {
      this.fetchCodeQuality();
    }

    if (this.shouldRenderSecurityReport) {
      this.fetchSecurity();
    }
  },
  template: `
    <div class="mr-state-widget prepend-top-default">
      <mr-widget-header :mr="mr" />
      <mr-widget-pipeline
        v-if="shouldRenderPipelines"
        :mr="mr" />
      <mr-widget-deployment
        v-if="shouldRenderDeployments"
        :mr="mr"
        :service="service" />
      <mr-widget-approvals
        v-if="mr.approvalsRequired"
        :mr="mr"
        :service="service" />
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
        v-if="shouldRenderSecurityReport"
        type="security"
        :status="securityStatus"
        loading-text="Loading security report"
        error-text="Failed to load security report"
        :success-text="securityText"
        :unresolvedIssues="mr.securityReport"
        />
      <div class="mr-widget-section">
        <component
          :is="componentName"
          :mr="mr"
          :service="service" />
        <mr-widget-related-links
          v-if="shouldRenderRelatedLinks"
          :related-links="mr.relatedLinks" />
      </div>
      <div class="mr-widget-footer" v-if="shouldRenderMergeHelp">
        <mr-widget-merge-help />
      </div>
    </div>
  `,
};
