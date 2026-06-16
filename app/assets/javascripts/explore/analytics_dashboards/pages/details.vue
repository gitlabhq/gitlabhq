<script>
import { computed } from 'vue';
import { GlDashboardLayout } from '@gitlab/ui';
import AnalyticsDashboardPanel from '~/analytics/shared/components/analytics_dashboard_panel.vue';
import DashboardFilters from '../components/dashboard_filters.vue';
import DashboardLoader from '../components/dashboard_loader.vue';

export default {
  name: 'ExploreAnalyticsDashboardDetails',
  components: {
    GlDashboardLayout,
    AnalyticsDashboardPanel,
    DashboardFilters,
    DashboardLoader,
  },
  // Provided as computed refs — options-API inject captures the value once
  // at setup, so plain values/getters won't propagate filter changes to panels.
  provide() {
    return {
      namespaceFullPath: computed(
        () => this.selectedProject?.fullPath || this.selectedGroup?.fullPath || '',
      ),
      namespaceId: computed(() => this.selectedProject?.id ?? this.selectedGroup?.id ?? null),
      namespaceName: computed(() => this.selectedProject?.name ?? this.selectedGroup?.name ?? ''),
      isProject: computed(() => Boolean(this.selectedProject)),

      // TODO: Investigate how to handle namespace specific checks
      //  These checks were previously done in controller and passed as data attributes
      //  but they are checks on a namespace level, we might need to move these
      //  into the relevant data sources that require the checks
      overviewCountsAggregationEnabled: null,
      dataSourceClickhouse: null,
    };
  },
  data() {
    return {
      filters: {},
      selectedGroup: null,
      selectedProject: null,
    };
  },
  methods: {
    panelTestId({ visualization: { slug = '' } }) {
      return `panel-${slug.replaceAll('_', '-')}`;
    },
    setDateRangeFilter({ dateRangeOption, startDate, endDate }) {
      this.filters = {
        ...this.filters,
        dateRangeOption,
        startDate,
        endDate,
      };
    },
    setProjectsFilter(projects) {
      const [project = null] = projects ?? [];
      this.selectedProject = project;
      this.filters = {
        ...this.filters,
        projects: project ? [project.fullPath] : [],
      };
    },
    setGroupsFilter(groups) {
      const [group = null] = groups ?? [];
      this.selectedGroup = group;
      // Clearing a group also clears the project (which lives under it).
      if (!group) {
        this.selectedProject = null;
      }
      this.filters = {
        ...this.filters,
        groups: group ? [group.fullPath] : [],
        projects: [],
      };
    },
  },
};
</script>
<template>
  <dashboard-loader>
    <template #dashboard="{ config, cellHeight, minCellHeight, isSystemDashboard }">
      <gl-dashboard-layout
        :config="config"
        :cell-height="cellHeight"
        :min-cell-height="minCellHeight"
        :filters="filters"
      >
        <template #actions>
          <slot name="actions" :is-system-dashboard="isSystemDashboard"></slot>
        </template>

        <template #filters>
          <dashboard-filters
            :group-namespace="selectedGroup?.fullPath || ''"
            :dashboard-filters="config.filters"
            @set-date-range="setDateRangeFilter"
            @set-projects="setProjectsFilter"
            @set-groups="setGroupsFilter"
          />
        </template>

        <template #panel="{ panel }">
          <analytics-dashboard-panel
            :title="panel.title"
            :tooltip="panel.tooltip"
            :visualization="panel.visualization"
            :query-overrides="panel.queryOverrides"
            :filters="filters"
            :data-testid="panelTestId(panel)"
          />
        </template>
      </gl-dashboard-layout>
    </template>
  </dashboard-loader>
</template>
