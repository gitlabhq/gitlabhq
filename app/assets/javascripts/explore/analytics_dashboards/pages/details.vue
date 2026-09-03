<script>
import { computed } from 'vue';
import { GlButton, GlDashboardLayout, GlEmptyState, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';
import AnalyticsDashboardPanel from '~/analytics/shared/components/analytics_dashboard_panel.vue';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import DashboardFilters from '../components/dashboard_filters.vue';
import DashboardLoader from '../components/dashboard_loader.vue';
import { DATE_RANGE_OPTION_LAST_30_DAYS } from '../components/constants';

export default {
  name: 'ExploreAnalyticsDashboardDetails',
  components: {
    GlButton,
    GlDashboardLayout,
    GlEmptyState,
    GlTabs,
    GlTab,
    AnalyticsDashboardPanel,
    DashboardFilters,
    DashboardLoader,
  },
  mixins: [glSlotsMixin],
  i18n: {
    noNamespaceTitle: s__('AnalyticsDashboards|Select a group or project'),
    noNamespaceDescription: s__(
      'AnalyticsDashboards|Choose a group or project above to see this dashboard.',
    ),
    reset: s__('AnalyticsDashboards|Reset'),
    resetLabel: s__('AnalyticsDashboards|Reset filters'),
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

      // TODO: Investigate how to handle this namespace specific check. It was
      //  previously done in the controller and passed as a data attribute, but it
      //  reads the namespace's root ancestor, so it may need to move into the
      //  data sources that require it.
      //  dataSourceClickhouse is not listed here on purpose: it is an
      //  instance-wide setting provided by the page entry point.
      overviewCountsAggregationEnabled: null,
    };
  },
  data() {
    return {
      filters: {},
      selectedGroup: null,
      selectedProject: null,
      activeViewIndex: 0,
      filtersKey: 0,
      dashboardFilterConfig: null,
    };
  },
  computed: {
    hasNamespace() {
      return Boolean(this.selectedGroup || this.selectedProject);
    },
    // A selected namespace always counts. The date range always has a value,
    // so it only counts when it differs from the configured default.
    hasActiveFilters() {
      const { dateRangeOption } = this.filters;
      const defaultDateRange =
        this.dashboardFilterConfig?.dateRange?.defaultOption ?? DATE_RANGE_OPTION_LAST_30_DAYS;

      return Boolean(
        this.hasNamespace || (dateRangeOption && dateRangeOption !== defaultDateRange),
      );
    },
  },
  methods: {
    // Set the active tab from the `view` query param on load. Default to the
    // first view if the query param wasn't included, or has an invalid index.
    onDashboardLoaded({ config }) {
      this.dashboardFilterConfig = config.filters;

      const viewParam = getParameterByName('view');
      const viewIndex = (config.views ?? []).findIndex((_, index) => `${index}` === viewParam);

      this.activeViewIndex = viewIndex === -1 ? 0 : viewIndex;
    },
    hasViews(config) {
      return Boolean(config.views?.length);
    },
    // When a dashboard defines views, feed the active view's panels to the layout
    // so the shared grid re-renders as the user switches views.
    layoutConfig(config) {
      // Every panel is namespace-scoped, render none until a namespace is specified
      if (!this.hasNamespace) return { ...config, panels: [] };

      if (!this.hasViews(config)) return config;

      return { ...config, panels: config.views[this.activeViewIndex]?.panels || [] };
    },
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
    resetFilters() {
      this.filters = {};
      this.selectedGroup = null;
      this.selectedProject = null;
      // The controls own their selection, so remount them to clear it.
      this.filtersKey += 1;
    },
  },
};
</script>
<template>
  <dashboard-loader @loaded="onDashboardLoaded">
    <template #dashboard="{ config, cellHeight, minCellHeight, isSystemDashboard }">
      <!--
        Keying the layout by the active view forces a clean remount of the grid on
        view change. This routes panel rendering through GlDashboardLayout's initial
        load (which does not scroll) instead of Gridstack's incremental "added" event,
        which smooth-scrolls to the last panel and jumps the page to the bottom.
      -->
      <gl-dashboard-layout
        :key="activeViewIndex"
        :config="layoutConfig(config)"
        :cell-height="cellHeight"
        :min-cell-height="minCellHeight"
        :filters="filters"
      >
        <template v-if="glSlots().actions" #actions>
          <slot name="actions" :is-system-dashboard="isSystemDashboard"></slot>
        </template>

        <template #filters>
          <gl-tabs
            v-if="hasViews(config)"
            v-model="activeViewIndex"
            class="gl-basis-full"
            content-class="gl-hidden"
            sync-active-tab-with-query-params
            query-param-name="view"
            data-testid="dashboard-views"
          >
            <gl-tab v-for="(view, index) in config.views" :key="index" :title="view.title" />
          </gl-tabs>
          <dashboard-filters
            :key="filtersKey"
            :group-namespace="selectedGroup?.fullPath || ''"
            :dashboard-filters="config.filters"
            @set-date-range="setDateRangeFilter"
            @set-projects="setProjectsFilter"
            @set-groups="setGroupsFilter"
          />
          <!-- Outside the filter bar so the remount above cannot destroy it mid-click. -->
          <gl-button
            category="secondary"
            icon="retry"
            class="gl-mb-5 gl-basis-full md:gl-basis-auto md:gl-self-end"
            :aria-label="$options.i18n.resetLabel"
            :disabled="!hasActiveFilters"
            data-testid="dashboard-filters-reset"
            @click="resetFilters"
          >
            {{ $options.i18n.reset }}
          </gl-button>
        </template>

        <template #panel="{ panel }">
          <analytics-dashboard-panel
            :title="panel.title"
            :title-icon="panel.titleIcon || ''"
            :tooltip="panel.tooltip"
            :visualization="panel.visualization"
            :query-overrides="panel.queryOverrides"
            :views="panel.views"
            :filters="filters"
            :data-testid="panelTestId(panel)"
          />
        </template>

        <template v-if="!hasNamespace" #empty-state>
          <gl-empty-state
            :title="$options.i18n.noNamespaceTitle"
            :description="$options.i18n.noNamespaceDescription"
            illustration-name="empty-dashboard-md"
            data-testid="no-namespace-empty-state"
          />
        </template>
      </gl-dashboard-layout>
    </template>
  </dashboard-loader>
</template>
