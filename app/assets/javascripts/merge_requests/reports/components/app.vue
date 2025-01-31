<script>
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';
import {
  BLOCKERS_ROUTE,
  CODE_QUALITY_ROUTE,
  LICENSE_COMPLIANCE_ROUTE,
  SECURITY_ROUTE,
} from '../constants';
import ReportListItem from './report_list_item.vue';

export default {
  name: 'MergeRequestReportsApp',
  components: {
    ReportListItem,
    BlockersListItem: () =>
      import('ee_component/merge_requests/reports/components/blockers_list_item.vue'),
  },
  routeNames: {
    BLOCKERS_ROUTE,
    CODE_QUALITY_ROUTE,
    SECURITY_ROUTE,
    LICENSE_COMPLIANCE_ROUTE,
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
  <div class="gl-grid gl-grid-cols-[1fr] gl-gap-5 md:gl-min-h-31 md:gl-grid-cols-[200px,1fr]">
    <h2 class="gl-sr-only">{{ s__('MrReports|Reports') }}</h2>
    <aside
      class="gl-border-b gl-border-default gl-pb-3 gl-pt-5 md:gl-border-r md:gl-border-0 md:gl-pr-5"
    >
      <nav>
        <blockers-list-item v-if="hasPolicies" />
        <h3 class="gl-heading-6 gl-mb-0 gl-py-3 gl-pl-3 gl-text-sm gl-font-[700] gl-leading-normal">
          {{ s__('MrReports|All reports') }}
        </h3>
        <ul class="gl-m-0 gl-list-none gl-p-0">
          <li class="gl-my-1">
            <report-list-item :to="$options.routeNames.CODE_QUALITY_ROUTE" status-icon="warning">
              {{ s__('MrReports|Code quality') }}
            </report-list-item>
          </li>
        </ul>
      </nav>
    </aside>
    <section class="md:gl-pt-5">
      <router-view :mr="mr" />
    </section>
  </div>
</template>
