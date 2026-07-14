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
  emits: ['loaded'],
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
  },
  watch: {
    dashboard() {
      this.breadcrumbState.update({ name: this.config.title, slug: this.slug });
      // Emit the processed config so consumers receive panels with unique ids,
      // matching what the slot-scoped config renders.
      this.$emit('loaded', JSON.parse(JSON.stringify({ ...this.dashboard, config: this.config })));
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
      :cell-height="cellHeight"
      :min-cell-height="minCellHeight"
      :is-system-dashboard="isSystemDashboard"
    ></slot>
  </div>
</template>
