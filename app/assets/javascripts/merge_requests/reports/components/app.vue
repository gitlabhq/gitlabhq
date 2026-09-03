<script>
import { defineAsyncComponent } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import mergeRequestData, { PIPELINE_STATE } from '~/merge_requests/reports/merge_request_data';
import {
  SECURITY_SCAN_ROUTE,
  LICENSE_COMPLIANCE_ROUTE,
  CODE_QUALITY_ROUTE,
  ROOT_ROUTE,
  EMPTY_STATE_NO_PIPELINE,
  EMPTY_STATE_PIPELINE_RUNNING,
  EMPTY_STATE_NO_REPORTS,
} from '../constants';
import ReportsEmptyState from './reports_empty_state.vue';

const REPORT_ROUTES = [SECURITY_SCAN_ROUTE, LICENSE_COMPLIANCE_ROUTE, CODE_QUALITY_ROUTE];
const OWNED_ROUTES = [ROOT_ROUTE, ...REPORT_ROUTES];

export default {
  name: 'MergeRequestReportsApp',
  components: {
    GlLoadingIcon,
    ReportsEmptyState,
    SecurityScansProvider: defineAsyncComponent(
      () =>
        import('ee_component/merge_requests/reports/security_scans/security_scans_provider.vue'),
    ),
    SecurityNavItem: defineAsyncComponent(
      () => import('ee_component/merge_requests/reports/security_scans/security_nav_item.vue'),
    ),
    LicenseComplianceProvider: defineAsyncComponent(
      () =>
        import('ee_component/merge_requests/reports/license_compliance/license_compliance_provider.vue'),
    ),
    LicenseComplianceNavItem: defineAsyncComponent(
      () =>
        import('ee_component/merge_requests/reports/license_compliance/license_compliance_nav_item.vue'),
    ),
    CodeQualityProvider: defineAsyncComponent(
      () => import('~/merge_requests/reports/code_quality/code_quality_provider.vue'),
    ),
    CodeQualityNavItem: defineAsyncComponent(
      () => import('~/merge_requests/reports/code_quality/code_quality_nav_item.vue'),
    ),
  },
  mixins: [mergeRequestData],
  inject: {
    basePath: { default: '' },
  },
  data() {
    return {
      hasSecurityScans: null,
    };
  },
  computed: {
    configuredRoutes() {
      const isConfigured = {
        [SECURITY_SCAN_ROUTE]: this.hasSecurityScans,
        [LICENSE_COMPLIANCE_ROUTE]: this.hasLicenseComplianceReports,
        [CODE_QUALITY_ROUTE]: this.hasCodeQualityReports,
      };

      return REPORT_ROUTES.filter((route) => isConfigured[route]);
    },
    isPipelineComplete() {
      return this.pipelineState === PIPELINE_STATE.complete;
    },
    isSecurityScanStateKnown() {
      return this.hasSecurityScans !== null;
    },
    hasConfiguredReports() {
      return this.isPipelineComplete && this.configuredRoutes.length > 0;
    },
    emptyStateType() {
      if (this.pipelineState === PIPELINE_STATE.noPipeline) return EMPTY_STATE_NO_PIPELINE;
      if (this.pipelineState === PIPELINE_STATE.running) return EMPTY_STATE_PIPELINE_RUNNING;
      if (this.isPipelineComplete && this.isSecurityScanStateKnown) return EMPTY_STATE_NO_REPORTS;
      return '';
    },
    pipelinePath() {
      return this.mr?.pipeline?.path || '';
    },
  },
  watch: {
    $route() {
      this.syncRouteWithConfiguredReports();
    },
  },
  mounted() {
    window.mrTabs?.eventHub.$on('MergeRequestTabChange', this.onTabChange);
  },
  beforeDestroy() {
    window.mrTabs?.eventHub.$off('MergeRequestTabChange', this.onTabChange);
  },
  methods: {
    onSecurityScansChange(hasScans) {
      this.hasSecurityScans = hasScans;
      this.syncRouteWithConfiguredReports();
    },
    onTabChange(action) {
      if (action === 'reports') this.syncRouteWithConfiguredReports();
    },
    syncRouteWithConfiguredReports() {
      if (!this.isPipelineComplete) return;
      if (!this.isSecurityScanStateKnown) return;
      if (!window.location.pathname.startsWith(this.basePath)) return;

      const { name } = this.$route;
      if (!OWNED_ROUTES.includes(name)) return;
      if (this.configuredRoutes.includes(name)) return;

      const [target = ROOT_ROUTE] = this.configuredRoutes;
      if (name === target) return;

      this.$router.replace({ name: target }).catch(() => {});
    },
  },
};
</script>

<template>
  <div
    class="gl-grid gl-grid-cols-[1fr] gl-gap-5 @md/panel:gl-min-h-31"
    :class="{ '@md/panel:gl-grid-cols-[200px,1fr]': hasConfiguredReports }"
  >
    <h2 class="gl-sr-only">{{ s__('MrReports|Reports') }}</h2>
    <aside
      v-show="hasConfiguredReports"
      class="gl-border-b gl-border-default gl-pb-3 gl-pt-5 @md/panel:gl-border-r @md/panel:gl-border-0 @md/panel:gl-pr-5"
    >
      <nav>
        <template v-if="isPipelineComplete">
          <security-scans-provider :mr="mr" @enabled-scans-change="onSecurityScansChange">
            <security-nav-item v-if="hasSecurityScans" />
          </security-scans-provider>
          <license-compliance-provider v-if="hasLicenseComplianceReports" :mr="mr">
            <license-compliance-nav-item />
          </license-compliance-provider>
          <code-quality-provider v-if="hasCodeQualityReports" :mr="mr">
            <code-quality-nav-item />
          </code-quality-provider>
        </template>
      </nav>
    </aside>
    <section class="@md/panel:gl-pt-5">
      <keep-alive v-if="hasConfiguredReports">
        <router-view :mr="mr" />
      </keep-alive>
      <div v-else role="status" aria-live="polite">
        <reports-empty-state
          v-if="emptyStateType"
          :type="emptyStateType"
          :pipeline-path="pipelinePath"
        />
        <gl-loading-icon v-else size="lg" />
      </div>
    </section>
  </div>
</template>
