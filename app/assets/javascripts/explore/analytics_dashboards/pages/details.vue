<script>
import { computed } from 'vue';
import { GlButton, GlDashboardLayout, GlEmptyState, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getParameterByName, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import AnalyticsDashboardPanel from '~/analytics/shared/components/analytics_dashboard_panel.vue';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import SectionHeader from '~/analytics/analytics_dashboards/components/section_header.vue';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import DashboardFilters from '../components/dashboard_filters.vue';
import DashboardLoader from '../components/dashboard_loader.vue';
import { DATE_RANGE_OPTION_LAST_30_DAYS, SCOPE_FILTER_QUERY_NAME } from '../components/constants';
import {
  dateRangeFilterFromQuery,
  dateRangeFilterToQueryParams,
  dateRangeFilterToUtc,
  dateRangeOptionToFilter,
  getDateRangeOption,
} from '../components/utils';

export default {
  name: 'ExploreAnalyticsDashboardDetails',
  components: {
    GlButton,
    GlDashboardLayout,
    GlEmptyState,
    GlTabs,
    GlTab,
    AnalyticsDashboardPanel,
    SectionHeader,
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
    scopeError: s__('AnalyticsDashboards|Failed to load groups and projects. Please try again.'),
  },
  // Provided as computed refs — options-API inject captures the value once
  // at setup, so plain values/getters won't propagate filter changes to panels.
  provide() {
    return {
      namespaceFullPath: computed(() => this.selectedNamespaceFullPath),
      namespaceId: computed(() => this.primaryNamespace?.id ?? null),
      namespaceName: computed(() => this.selectedNamespaceName),
      isProject: computed(() => this.isProjectScope),

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
      selectedNamespaces: [],
      activeViewIndex: 0,
      viewCount: 0,
      filtersKey: 0,
      dashboardFilterConfig: null,
      alert: null,
      // The picker enforces the upper limit, so hand everything over as-is.
      scopePaths: (getParameterByName(SCOPE_FILTER_QUERY_NAME) ?? '').split(',').filter(Boolean),
    };
  },
  computed: {
    hasNamespace() {
      return this.selectedNamespaces.length > 0;
    },
    primaryNamespace() {
      return this.selectedNamespaces[0] ?? null;
    },
    selectedNamespaceName() {
      return this.primaryNamespace?.name ?? '';
    },
    selectedNamespaceFullPath() {
      return this.primaryNamespace?.fullPath ?? '';
    },
    isProjectScope() {
      return this.primaryNamespace?.type === TYPENAME_PROJECT;
    },
    // The filters are held in local time, the way the picker and the URL work. Panel queries
    // run in whole UTC days, so the range is converted here to be passed to the panels.
    utcFilters() {
      return dateRangeFilterToUtc(this.filters);
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
  // createAlert renders into the global flash container, which outlives this page, so an alert
  // raised here would otherwise follow the user to the next dashboard.
  beforeDestroy() {
    this.alert?.dismiss();
  },
  methods: {
    // Set the active tab from the `view` query param on load. Default to the
    // first view if the query param wasn't included, or has an invalid index.
    onDashboardLoaded({ config }) {
      this.dashboardFilterConfig = config.filters;
      this.filters = this.initialDateRangeFilter();

      const viewParam = getParameterByName('view');
      const viewIndex = (config.views ?? []).findIndex((_, index) => `${index}` === viewParam);

      this.activeViewIndex = viewIndex === -1 ? 0 : viewIndex;
      this.viewCount = config.views?.length ?? 0;
    },
    footerFor({ footer }) {
      const view = footer?.dashboardViewLink?.view;

      if (!Number.isInteger(view) || view >= this.viewCount) return null;

      return footer;
    },
    // GlTabs only writes the query param from its own click handler, so sync it here.
    selectDashboardView(viewIndex) {
      this.activeViewIndex = viewIndex;
      updateHistory({ url: setUrlParams({ view: viewIndex }), title: document.title });
    },
    hasViews(config) {
      return Boolean(config.views?.length);
    },
    activeDuoPrompts(config) {
      const viewPrompts = this.hasViews(config)
        ? config.views[this.activeViewIndex]?.duoPrompts
        : null;

      return viewPrompts ?? config.duoPrompts ?? [];
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
    sectionTestId({ section: { title = '' } }) {
      return `section-${title.toLowerCase().replaceAll(' ', '-')}`;
    },
    setDateRangeFilter({ dateRangeOption, startDate, endDate }) {
      this.filters = {
        ...this.filters,
        dateRangeOption,
        startDate,
        endDate,
      };
      this.syncDateRangeToUrl(this.filters);
    },
    // Written to history rather than through the router, for the same reason as the scope
    // filter below. Replaced, not pushed, so Back leaves the dashboard rather than walking
    // through every range the user tried.
    syncDateRangeToUrl(filter) {
      updateHistory({
        url: setUrlParams(dateRangeFilterToQueryParams(filter)),
        replace: true,
      });
    },
    // The picker emits every pick at once; each namespace's type says whether it belongs in the
    // groups list or the projects list, since panels read the two separately.
    setScopeFilter(namespaces) {
      this.selectedNamespaces = namespaces;
      this.filters = {
        ...this.filters,
        groups: this.pathsOfType(TYPENAME_GROUP),
        projects: this.pathsOfType(TYPENAME_PROJECT),
      };

      this.scopePaths = namespaces.map(({ fullPath }) => fullPath);
      this.syncScopeToUrl(this.scopePaths);
    },
    pathsOfType(type) {
      return this.selectedNamespaces
        .filter((namespace) => namespace.type === type)
        .map(({ fullPath }) => fullPath);
    },
    // Written to history rather than through the router, because GlTabs pushes the `view` param
    // the same way: routing this would rebuild the URL from a $route that never saw that push,
    // dropping the active view. Replaced, not pushed, so Back leaves the dashboard.
    syncScopeToUrl(fullPaths) {
      updateHistory({
        url: setUrlParams({ [SCOPE_FILTER_QUERY_NAME]: fullPaths.join(',') || null }),
        replace: true,
      });
    },
    // The picker reports to Sentry itself, so this only has to tell the user. Without it a failed
    // query leaves an empty dropdown with nothing to explain why.
    onScopeError(error) {
      // createAlert only detaches the element it replaces, leaving the instance mounted, and
      // the handle it would be dismissed by is about to be overwritten.
      this.alert?.dismiss();
      this.alert = createAlert({
        message: this.$options.i18n.scopeError,
        error,
        captureError: false,
      });
    },
    // The date range picker renders the dashboard's configured default without emitting it,
    // so seed the range to match. Otherwise a panel falls back to its own default window
    // and the first load can show a different range than the picker names.
    defaultDateRangeFilter() {
      const { dateRange = {} } = this.dashboardFilterConfig ?? {};

      // dashboard_filters.vue renders the picker whenever dateRange.enabled is not false, so
      // this must mirror that: `!dateRange.enabled` would render a picker with nothing behind it.
      if (dateRange.enabled === false) return {};

      const option =
        getDateRangeOption(dateRange.defaultOption) ??
        getDateRangeOption(DATE_RANGE_OPTION_LAST_30_DAYS);

      return dateRangeOptionToFilter(option);
    },
    // A reloaded or shared link restores the range it names, so the page and the picker
    // agree with the URL on load. Anything the URL cannot supply falls back to the default.
    initialDateRangeFilter() {
      const { dateRange = {} } = this.dashboardFilterConfig ?? {};

      if (dateRange.enabled === false) return this.defaultDateRangeFilter();

      const fromQuery = dateRangeFilterFromQuery(window.location.search, {
        ...(dateRange.options && { options: dateRange.options }),
        daysLimit: dateRange.numberOfDaysLimit ?? 0,
      });

      return fromQuery ?? this.defaultDateRangeFilter();
    },
    resetFilters() {
      this.filters = this.defaultDateRangeFilter();
      this.selectedNamespaces = [];
      this.scopePaths = [];
      this.syncScopeToUrl([]);
      // Cleared rather than set to the default, so the URL only names a range the user chose.
      this.syncDateRangeToUrl({});
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
        class="explore-analytics-dashboard"
        :config="layoutConfig(config)"
        :cell-height="cellHeight"
        :min-cell-height="minCellHeight"
        :filters="utcFilters"
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
            class="explore-dashboard-filters"
            :dashboard-filters="config.filters"
            :scope-paths="scopePaths"
            :date-range-filter="filters"
            @set-date-range="setDateRangeFilter"
            @set-scope="setScopeFilter"
            @error="onScopeError"
          />
          <!-- Outside the filter bar so the remount above cannot destroy it mid-click. -->
          <gl-button
            category="secondary"
            icon="retry"
            class="gl-basis-full md:gl-basis-auto md:gl-self-end"
            :aria-label="$options.i18n.resetLabel"
            :disabled="!hasActiveFilters"
            data-testid="dashboard-filters-reset"
            @click="resetFilters"
          >
            {{ $options.i18n.reset }}
          </gl-button>
          <slot
            name="filter-actions"
            :namespace-name="selectedNamespaceName"
            :namespace-full-path="selectedNamespaceFullPath"
            :filters="filters"
            :panels="layoutConfig(config).panels"
            :duo-prompts="activeDuoPrompts(config)"
            :is-project="isProjectScope"
            :is-system-dashboard="isSystemDashboard"
          ></slot>
        </template>

        <template #panel="{ panel }">
          <section-header
            v-if="panel.section"
            :title="panel.section.title"
            :description="panel.section.description"
            :tooltip="panel.section.tooltip"
            :data-testid="sectionTestId(panel)"
          />
          <analytics-dashboard-panel
            v-else
            :title="panel.title"
            :title-icon="panel.titleIcon || ''"
            :tooltip="panel.tooltip"
            :footer="footerFor(panel)"
            :visualization="panel.visualization"
            :query-overrides="panel.queryOverrides"
            :views="panel.views"
            :filters="utcFilters"
            :data-testid="panelTestId(panel)"
            @select-dashboard-view="selectDashboardView"
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
