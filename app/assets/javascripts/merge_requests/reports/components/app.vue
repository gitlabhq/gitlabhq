<script>
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';
import ReportWidgetContainer from 'ee_else_ce/vue_merge_request_widget/components/widget/app.vue';

export default {
  name: 'MergeRequestReportsApp',
  components: {
    ReportWidgetContainer,
    BlockersListItem: () =>
      import('ee_component/merge_requests/reports/components/blockers_list_item.vue'),
  },
  inject: ['hasPolicies'],
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
        <blockers-list-item v-if="hasPolicies" />
        <div v-if="mr">
          <h3
            class="gl-heading-6 gl-mb-0 gl-py-3 gl-pl-3 gl-text-sm gl-font-[700] gl-leading-normal"
          >
            {{ s__('MrReports|All reports') }}
          </h3>
          <report-widget-container
            :mr="mr"
            reports-tab-sidebar
            data-testid="reports-widget-sidebar"
          />
        </div>
      </nav>
    </aside>
    <section class="@md/panel:gl-pt-5">
      <router-view :mr="mr" />
    </section>
  </div>
</template>
