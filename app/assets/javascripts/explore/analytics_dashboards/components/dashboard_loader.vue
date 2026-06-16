<script>
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { isNumeric } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import {
  GRID_HEIGHT_COMPACT,
  GRID_HEIGHT_COMPACT_CELL_HEIGHT,
  GRID_HEIGHT_COMPACT_MIN_CELL_HEIGHT,
} from '../constants';
import { convertToDashboardGraphQLId, getUniquePanelId } from '../utils';
import getDashboardQuery from '../graphql/get_dashboard.query.graphql';
import getSystemDashboardQuery from '../graphql/get_system_dashboard.query.graphql';

export default {
  name: 'DashboardLoader',
  components: { GlSkeletonLoader, GlAlert },
  inject: ['breadcrumbState'],
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
      // Custom dashboards are routed by their numeric ID; system dashboards by their slug.
      return !isNumeric(this.slug);
    },
    dashboardId() {
      return this.isSystemDashboard ? this.slug : convertToDashboardGraphQLId(this.slug);
    },
    isLoading() {
      return Boolean(this.$apollo.queries.dashboard?.loading);
    },
    config() {
      if (!this.dashboard?.config) return {};
      // Each panel needs a uniqueId or the prop validator for GlDashboardLayout will fail
      const { panels, ...rest } = this.dashboard.config;
      return {
        ...rest,
        panels: panels.map(({ id, ...panel }) => ({
          ...panel,
          id: getUniquePanelId(),
        })),
      };
    },
    cellHeight() {
      return this.config.gridHeight === GRID_HEIGHT_COMPACT
        ? GRID_HEIGHT_COMPACT_CELL_HEIGHT
        : undefined;
    },
    minCellHeight() {
      return this.config.gridHeight === GRID_HEIGHT_COMPACT
        ? GRID_HEIGHT_COMPACT_MIN_CELL_HEIGHT
        : undefined;
    },
    hasPanels() {
      return this.config.panels && this.config.panels.length > 0;
    },
  },
  watch: {
    dashboard() {
      this.breadcrumbState.update({ name: this.config.title, slug: this.slug });
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
      error(err) {
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
  <div v-else>
    <slot
      name="dashboard"
      :dashboard-id="dashboardId"
      :config="config"
      :has-panels="hasPanels"
      :cell-height="cellHeight"
      :min-cell-height="minCellHeight"
      :is-system-dashboard="isSystemDashboard"
    ></slot>
  </div>
</template>
