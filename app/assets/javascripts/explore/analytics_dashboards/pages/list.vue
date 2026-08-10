<script>
import { GlTabs } from '@gitlab/ui';
import IndexLayout from '~/vue_shared/components/index_layout.vue';
import DashboardListTab from '../components/dashboard_list_tab.vue';

export default {
  name: 'ExploreAnalyticsDashboardsList',
  components: {
    DashboardListTab,
    GlTabs,
    IndexLayout,
  },
};
</script>
<template>
  <index-layout
    :heading="__('Analytics dashboards')"
    :description="
      s__('AnalyticsDashboards|Keep your teams aligned around the metrics that matter most.')
    "
  >
    <gl-tabs content-class="gl-p-0">
      <dashboard-list-tab
        :title="s__('AnalyticsDashboards|Created by GitLab')"
        :sr-text="s__('AnalyticsDashboards|Dashboards created by GitLab')"
        scope="GITLAB"
      />
    </gl-tabs>
  </index-layout>
</template>
