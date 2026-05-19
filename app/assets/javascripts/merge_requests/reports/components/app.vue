<script>
import { GlLoadingIcon } from '@gitlab/ui';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';
import SmartInterval from '~/smart_interval';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import { s__ } from '~/locale';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';

const PIPELINE_STATE = {
  loading: 'LOADING',
  noPipeline: 'NO_PIPELINE',
  running: 'RUNNING',
  complete: 'COMPLETE',
};

// 5s → 10s → 20s → 40s → 80s → 120s → repeats 120s until done
const MR_POLLING_SETTINGS = {
  startingInterval: secondsToMilliseconds(5), // Poll starts at 5s
  incrementByFactorOf: 2, // Doubles each time
  maxInterval: secondsToMilliseconds(120), // Caps at 2 mins
};

export default {
  name: 'MergeRequestReportsApp',
  components: {
    GlLoadingIcon,
    StatusIcon,
    SecurityScansProvider: () =>
      import('ee_component/merge_requests/reports/security_scans/security_scans_provider.vue'),
    SecurityNavItem: () =>
      import('ee_component/merge_requests/reports/security_scans/security_nav_item.vue'),
    LicenseComplianceProvider: () =>
      import(
        'ee_component/merge_requests/reports/license_compliance/license_compliance_provider.vue'
      ),
    LicenseComplianceNavItem: () =>
      import(
        'ee_component/merge_requests/reports/license_compliance/license_compliance_nav_item.vue'
      ),
    CodeQualityProvider: () =>
      import('~/merge_requests/reports/code_quality/code_quality_provider.vue'),
    CodeQualityNavItem: () =>
      import('~/merge_requests/reports/code_quality/code_quality_nav_item.vue'),
  },
  data() {
    return {
      mr: null,
    };
  },
  computed: {
    pipelineState() {
      if (!this.mr) return PIPELINE_STATE.loading;
      if (!this.mr.pipelineIid) return PIPELINE_STATE.noPipeline;
      if (this.mr.isPipelineActive) return PIPELINE_STATE.running;
      return PIPELINE_STATE.complete;
    },
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
  created() {
    if (
      window.gl?.mrWidgetData?.merge_request_cached_widget_path &&
      window.gl?.mrWidgetData?.merge_request_widget_path
    ) {
      MRWidgetService.fetchInitialData()
        .then(({ data }) => {
          this.mr = new MRWidgetStore({ ...window.gl.mrWidgetData, ...data });
          this.initMrPolling();
        })
        .catch(() => {});
    }
  },
  beforeDestroy() {
    this.mrPollingInterval?.destroy();
  },
  methods: {
    initMrPolling() {
      if (this.pipelineState === PIPELINE_STATE.complete) return;

      this.mrPollingInterval = new SmartInterval({
        callback: () =>
          MRWidgetService.fetchInitialData()
            .then(({ data }) => {
              this.mr.setData({ ...window.gl.mrWidgetData, ...data });
              if (this.pipelineState === PIPELINE_STATE.complete) {
                this.mrPollingInterval.destroy();
              }
            })
            .catch(() => {}),
        ...MR_POLLING_SETTINGS,
        immediateExecution: false,
      });
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
