<script>
import { GlLoadingIcon } from '@gitlab/ui';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';
import SmartInterval from '~/smart_interval';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';

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
    SecurityScansProvider: () =>
      import('ee_component/merge_requests/reports/components/security_scans_provider.vue'),
    SecurityNavItem: () => import('~/merge_requests/reports/components/security_nav_item.vue'),
  },
  data() {
    return {
      mr: null,
    };
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
      if (!this.mr.isPipelineActive) return;

      this.mrPollingInterval = new SmartInterval({
        callback: () =>
          MRWidgetService.fetchInitialData()
            .then(({ data }) => {
              this.mr.setData({ ...window.gl.mrWidgetData, ...data });
              if (!this.mr.isPipelineActive) {
                this.mrPollingInterval.destroy();
              }
            })
            .catch(() => {}),
        ...MR_POLLING_SETTINGS,
        immediateExecution: false,
      });
    },
  },
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
        <security-scans-provider v-if="mr" :mr="mr">
          <security-nav-item />
        </security-scans-provider>
      </nav>
    </aside>
    <section class="@md/panel:gl-pt-5">
      <router-view v-if="mr" :mr="mr" />
      <gl-loading-icon v-else size="lg" />
    </section>
  </div>
</template>
