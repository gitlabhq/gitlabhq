<script>
import { defineAsyncComponent } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';
import mergeRequestData, { PIPELINE_STATE } from '~/merge_requests/reports/merge_request_data';

export default {
  name: 'MergeRequestReportsApp',
  components: {
    GlLoadingIcon,
    StatusIcon,
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
  computed: {
    statusMessage() {
      if (this.pipelineState === PIPELINE_STATE.running) {
        return s__('MrReports|Waiting for pipeline to complete.');
      }
      if (this.pipelineState === PIPELINE_STATE.noPipeline) {
        return s__(
          'MrReports|No pipelines started yet. Results will appear when a pipeline completes.',
        );
      }
      return '';
    },
  },
  PIPELINE_STATE,
};
</script>

<template>
  <div
    class="gl-grid gl-grid-cols-[1fr] gl-gap-5 @md/panel:gl-min-h-31 @md/panel:gl-grid-cols-[200px,1fr]"
  >
    <h2 class="gl-sr-only">{{ s__('MrReports|Reports') }}</h2>
    <aside
      class="gl-border-b gl-border-default gl-pb-3 gl-pt-5 @md/panel:gl-border-r @md/panel:gl-border-0 @md/panel:gl-pr-5"
    >
      <nav>
        <template v-if="pipelineState === $options.PIPELINE_STATE.complete">
          <security-scans-provider :mr="mr">
            <security-nav-item />
          </security-scans-provider>
          <license-compliance-provider :mr="mr">
            <license-compliance-nav-item />
          </license-compliance-provider>
          <code-quality-provider :mr="mr">
            <code-quality-nav-item />
          </code-quality-provider>
        </template>
      </nav>
    </aside>
    <section class="@md/panel:gl-pt-5">
      <template v-if="pipelineState === $options.PIPELINE_STATE.complete">
        <keep-alive>
          <router-view :mr="mr" />
        </keep-alive>
      </template>
      <div
        v-show="statusMessage"
        class="gl-flex gl-px-5 gl-py-4"
        role="status"
        aria-live="polite"
        data-testid="status-message"
      >
        <status-icon v-if="pipelineState === $options.PIPELINE_STATE.running" :is-loading="true" />
        <span>{{ statusMessage }}</span>
      </div>
      <gl-loading-icon v-if="pipelineState === $options.PIPELINE_STATE.loading" size="lg" />
    </section>
  </div>
</template>
