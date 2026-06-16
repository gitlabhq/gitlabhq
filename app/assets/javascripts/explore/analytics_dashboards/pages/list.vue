<script>
import { GlTabs } from '@gitlab/ui';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import DashboardListTab from '../components/dashboard_list_tab.vue';

export default {
  name: 'ExploreAnalyticsDashboardsList',
  components: {
    DashboardListTab,
    GlTabs,
    PageHeading,
  },
};
</script>
<template>
  <div>
    <page-heading :heading="__('Analytics dashboards')">
      <template #description>
        {{
          s__('AnalyticsDashboards|Keep your teams aligned around the metrics that matter most.')
        }}
      </template>
    </page-heading>
    <gl-tabs content-class="gl-p-0">
      <dashboard-list-tab
        :title="s__('AnalyticsDashboards|Created by GitLab')"
        :sr-text="s__('AnalyticsDashboards|Dashboards created by GitLab')"
        scope="GITLAB"
      />
    </gl-tabs>
  </div>
</template>
