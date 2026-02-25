<script>
import { GlLoadingIcon } from '@gitlab/ui';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';

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
        })
        .catch(() => {});
    }
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
