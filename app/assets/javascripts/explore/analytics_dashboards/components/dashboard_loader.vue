<script>
import { GlSkeletonLoader, GlAlert, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import {
  FULL_DASHBOARD_WIDTH,
  GRID_HEIGHT_COMPACT,
  GRID_HEIGHT_COMPACT_CELL_HEIGHT,
  GRID_HEIGHT_COMPACT_MIN_CELL_HEIGHT,
} from '../constants';
import {
  assignLoadPriority,
  convertToDashboardGraphQLId,
  getUniquePanelId,
  isSystemDashboardSlug,
} from '../utils';
import getDashboardQuery from '../graphql/get_dashboard.query.graphql';
import getSystemDashboardQuery from '../graphql/get_system_dashboard.query.graphql';

// What the API answers for a dashboard the user may not see, such as one behind a disabled
// feature flag or a missing licence. It is deliberately the same answer as for one that is missing.
const RESOURCE_NOT_AVAILABLE_ERROR =
  "The resource that you are attempting to access does not exist or you don't have permission to perform this action";

const isResourceNotAvailable = ({ graphQLErrors = [] }) =>
  graphQLErrors.length > 0 &&
  graphQLErrors.every(({ message }) => message === RESOURCE_NOT_AVAILABLE_ERROR);

export default {
  name: 'DashboardLoader',
  components: { GlSkeletonLoader, GlAlert, GlEmptyState },
  inject: ['breadcrumbState', 'exploreAnalyticsDashboardsPath'],
  emits: ['loaded'],
  i18n: {
    notFound: s__('Analytics|Dashboard not found'),
    notFoundDescription: s__('Analytics|No dashboard matches the specified URL path.'),
    notFoundActionBtn: s__('Analytics|View available dashboards'),
  },
  data() {
    return {
      dashboard: null,
      error: null,
    };
  },
  computed: {
    slug() {
      return this.$route?.params.slug;
    },
    isSystemDashboard() {
      return isSystemDashboardSlug(this.slug);
    },
    dashboardId() {
      return this.isSystemDashboard ? this.slug : convertToDashboardGraphQLId(this.slug);
    },
    isLoading() {
      return Boolean(this.$apollo.queries.dashboard?.loading);
    },
    isNotFound() {
      return !this.dashboard;
    },
    config() {
      if (!this.dashboard?.config) return {};
      // Each panel needs a uniqueId or the prop validator for GlDashboardLayout will fail
      const { panels = [], views, ...rest } = this.dashboard.config;
      return {
        ...rest,
        panels: this.assignPanelIds(panels),
        ...(views
          ? { views: views.map((view) => ({ ...view, panels: this.assignPanelIds(view.panels) })) }
          : {}),
      };
    },
    // The raw schema value is `compact` (lowercased)
    isCompactGrid() {
      return this.config.gridHeight?.toUpperCase() === GRID_HEIGHT_COMPACT;
    },
    cellHeight() {
      return this.isCompactGrid ? GRID_HEIGHT_COMPACT_CELL_HEIGHT : undefined;
    },
    minCellHeight() {
      return this.isCompactGrid ? GRID_HEIGHT_COMPACT_MIN_CELL_HEIGHT : undefined;
    },
  },
  watch: {
    dashboard() {
      if (!this.dashboard) return;

      this.breadcrumbState.update({ name: this.config.title, slug: this.slug });
      // Emit the processed config so consumers receive panels with unique ids,
      // matching what the slot-scoped config renders.
      this.$emit('loaded', JSON.parse(JSON.stringify({ ...this.dashboard, config: this.config })));
    },
  },
  methods: {
    // The breadcrumb state outlives this page, so it would otherwise keep the last dashboard's name.
    // Dashboard cleared so a slug changed in place does not keep showing the previous dashboard.
    showNotFound() {
      this.dashboard = null;
      this.breadcrumbState.update({ name: this.$options.i18n.notFound, slug: this.slug });
    },
    assignPanelIds(panels = []) {
      const withIds = panels.map(({ id, ...panel }) => ({
        ...panel,
        // A section spans the dashboard, so its config omits a width. The grid
        // layout requires one, so fill it in here.
        ...(panel.section
          ? {
              gridAttributes: {
                width: FULL_DASHBOARD_WIDTH,
                ...panel.gridAttributes,
              },
            }
          : {}),
        id: getUniquePanelId(),
      }));

      // The grid slot drops `gridAttributes`, so each panel gets its load priority here, while
      // the position is still known.
      return assignLoadPriority(withIds);
    },
  },
  apollo: {
    dashboard: {
      query() {
        return this.isSystemDashboard ? getSystemDashboardQuery : getDashboardQuery;
      },
      variables() {
        if (this.isSystemDashboard) {
          return { slug: this.dashboardId };
        }
        return { id: this.dashboardId };
      },
      update({ customDashboard = {}, customSystemDashboard = {} }) {
        return this.isSystemDashboard ? customSystemDashboard : customDashboard;
      },
      result() {
        if (!this.dashboard) this.showNotFound();
      },
      error(err) {
        if (isResourceNotAvailable(err)) {
          this.showNotFound();
          return;
        }

        this.error = s__('AnalyticsDashboards|Failed to load dashboard. Please try again.');
        captureException(err);
      },
    },
  },
};
</script>
<template>
  <gl-skeleton-loader v-if="isLoading" class="gl-mt-5" />
  <gl-alert v-else-if="error" class="gl-mt-5" variant="danger" :dismissible="false">
    {{ error }}
  </gl-alert>
  <gl-empty-state
    v-else-if="isNotFound"
    :title="$options.i18n.notFound"
    :description="$options.i18n.notFoundDescription"
    :primary-button-text="$options.i18n.notFoundActionBtn"
    :primary-button-link="exploreAnalyticsDashboardsPath"
    illustration-name="empty-dashboard-md"
    data-testid="dashboard-not-found"
  />
  <div v-else>
    <slot
      name="dashboard"
      :dashboard-id="dashboardId"
      :config="config"
      :cell-height="cellHeight"
      :min-cell-height="minCellHeight"
      :is-system-dashboard="isSystemDashboard"
    ></slot>
  </div>
</template>
