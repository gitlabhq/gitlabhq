<script>
import { GlDashboardLayout, GlSkeletonLoader } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import {
  GRID_HEIGHT_COMPACT,
  GRID_HEIGHT_COMPACT_CELL_HEIGHT,
  GRID_HEIGHT_COMPACT_MIN_CELL_HEIGHT,
} from '../constants';
import { getUniquePanelId, convertToDashboardGraphQLId } from '../utils';
import getDashboardQuery from '../graphql/get_dashboard.query.graphql';

export default {
  name: 'ExploreAnalyticsDashboard',
  components: { GlDashboardLayout, GlSkeletonLoader },
  inject: ['breadcrumbState'],
  data() {
    return { dashboard: null, hasError: false };
  },
  computed: {
    dashboardId() {
      return convertToDashboardGraphQLId(this.$route?.params.slug);
    },
    dashboardConfig() {
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
    isLoading() {
      return Boolean(this.$apollo.queries.dashboard?.loading);
    },
    cellHeight() {
      return this.dashboardConfig?.gridHeight === GRID_HEIGHT_COMPACT
        ? GRID_HEIGHT_COMPACT_CELL_HEIGHT
        : undefined;
    },
    minCellHeight() {
      return this.dashboardConfig?.gridHeight === GRID_HEIGHT_COMPACT
        ? GRID_HEIGHT_COMPACT_MIN_CELL_HEIGHT
        : undefined;
    },
  },
  apollo: {
    dashboard: {
      query: getDashboardQuery,
      variables() {
        return { id: this.dashboardId };
      },
      update({ customDashboard = {} }) {
        return customDashboard;
      },
      error(err) {
        this.hasError = true;

        createAlert({
          message: s__('AnalyticsDashboards|Failed to load dashboard. Please try again.'),
          captureError: true,
          error: err,
        });
      },
    },
  },
  watch: {
    dashboard() {
      this.breadcrumbState.updateName(this.dashboardConfig?.title);
    },
  },
};
</script>
<template>
  <gl-skeleton-loader v-if="isLoading" />
  <div v-else>
    <span v-if="hasError"></span>
    <gl-dashboard-layout
      v-else
      :config="dashboardConfig"
      :cell-height="cellHeight"
      :min-cell-height="minCellHeight"
    >
      <template #title>
        <h2>{{ dashboardConfig.title }}</h2>
      </template>
    </gl-dashboard-layout>
  </div>
</template>
