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
      let newIssuesText;
      let resolvedIssuesText;
      let text = [];

      if (!newIssues.length && !resolvedIssues.length) {
        text.push('No changes to code quality');
      } else if (newIssues.length || resolvedIssues.length) {
        if (newIssues.length) {
          newIssuesText = ` degraded on ${newIssues.length} ${this.pointsText(newIssues)}`;
        }

        if (resolvedIssues.length) {
          resolvedIssuesText = ` improved on ${resolvedIssues.length} ${this.pointsText(resolvedIssues)}`;
        }

        const connector = (newIssues.length > 0 && resolvedIssues.length > 0) ? ' and' : null;

        text = ['Code quality'];
        if (resolvedIssuesText) {
          text.push(resolvedIssuesText);
        }

        if (connector) {
          text.push(connector);
        }

        if (newIssuesText) {
          text.push(newIssuesText);
        }
      }

      return text.join('');
    },
    securityText() {
      const { securityReport } = this.mr;
      if (securityReport.length) {
        return `${securityReport.length} security ${this.pluralizeVulnerability(securityReport.length)} detected`;
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
    pluralizeVulnerability(length) {
      return length === 1 ? 'vulnerability' : 'vulnerabilities';
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

    fetchSecurity() {
      this.isLoadingSecurity = true;

      this.service.fetchReport(this.mr.security.sast)
        .then((data) => {
          this.mr.setSecurityReport(data);
          this.isLoadingSecurity = false;
        })
        .catch(() => {
          this.isLoadingSecurity = false;
          this.loadingSecurityFailed = true;
        });
    },

    pointsText(issues) {
      return gl.text.pluralize('point', issues.length);
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
        loadingText="Loading codeclimate report"
        errorText="Failed to load codeclimate report"
        :successText="codequalityText"
        :unresolvedIssues="mr.codeclimateMetrics.newIssues"
        :resolvedIssues="mr.codeclimateMetrics.resolvedIssues"
        />
      <collapsible-section
        v-if="shouldRenderSecurityReport"
        type="security"
        :status="securityStatus"
        loadingText="Loading security report"
        errorText="Failed to load security report"
        :successText="securityText"
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
