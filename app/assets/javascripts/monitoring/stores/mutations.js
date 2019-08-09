import Vue from 'vue';
import * as types from './mutation_types';
import { normalizeMetrics, sortMetrics, normalizeQueryResult } from './utils';

export default {
  [types.REQUEST_METRICS_DATA](state) {
    state.emptyState = 'loading';
    state.showEmptyState = true;
  },
  [types.RECEIVE_METRICS_DATA_SUCCESS](state, groupData) {
    state.groups = groupData.map(group => {
      let { metrics } = group;

      // for backwards compatibility, and to limit Vue template changes:
      // for each group alias panels to metrics
      // for each panel alias metrics to queries
      if (state.useDashboardEndpoint) {
        metrics = group.panels.map(panel => ({
          ...panel,
          queries: panel.metrics,
        }));
      }

      return {
        ...group,
        metrics: normalizeMetrics(sortMetrics(metrics)),
      };
    });

    if (!state.groups.length) {
      state.emptyState = 'noData';
    } else {
      state.showEmptyState = false;
    }
  },
  [types.RECEIVE_METRICS_DATA_FAILURE](state, error) {
    state.emptyState = error ? 'unableToConnect' : 'noData';
    state.showEmptyState = true;
  },
  [types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS](state, deployments) {
    state.deploymentData = deployments;
  },
  [types.RECEIVE_DEPLOYMENTS_DATA_FAILURE](state) {
    state.deploymentData = [];
  },
  [types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS](state, environments) {
    state.environments = environments;
  },
  [types.RECEIVE_ENVIRONMENTS_DATA_FAILURE](state) {
    state.environments = [];
  },
  [types.SET_QUERY_RESULT](state, { metricId, result }) {
    if (!metricId || !result || result.length === 0) {
      return;
    }

    state.showEmptyState = false;

    state.groups.forEach(group => {
      group.metrics.forEach(metric => {
        metric.queries.forEach(query => {
          if (query.metric_id === metricId) {
            state.metricsWithData.push(metricId);
            // ensure dates/numbers are correctly formatted for charts
            const normalizedResults = result.map(normalizeQueryResult);
            Vue.set(query, 'result', Object.freeze(normalizedResults));
          }
        });
      });
    });
  },
  [types.SET_ENDPOINTS](state, endpoints) {
    state.metricsEndpoint = endpoints.metricsEndpoint;
    state.environmentsEndpoint = endpoints.environmentsEndpoint;
    state.deploymentsEndpoint = endpoints.deploymentsEndpoint;
    state.dashboardEndpoint = endpoints.dashboardEndpoint;
    state.currentDashboard = endpoints.currentDashboard;
    state.projectPath = endpoints.projectPath;
  },
  [types.SET_DASHBOARD_ENABLED](state, enabled) {
    state.useDashboardEndpoint = enabled;
  },
  [types.SET_MULTIPLE_DASHBOARDS_ENABLED](state, enabled) {
    state.multipleDashboardsEnabled = enabled;
  },
  [types.SET_GETTING_STARTED_EMPTY_STATE](state) {
    state.emptyState = 'gettingStarted';
  },
  [types.SET_NO_DATA_EMPTY_STATE](state) {
    state.showEmptyState = true;
    state.emptyState = 'noData';
  },
  [types.SET_ALL_DASHBOARDS](state, dashboards) {
    state.allDashboards = dashboards;
  },
  [types.SET_ADDITIONAL_PANEL_TYPES_ENABLED](state, enabled) {
    state.additionalPanelTypesEnabled = enabled;
  },
  [types.SET_SHOW_ERROR_BANNER](state, enabled) {
    state.showErrorBanner = enabled;
  },
  [types.SET_EXPORT_METRICS_TO_CSV_ENABLED](state, enabled) {
    state.exportMetricsToCsvEnabled = enabled;
  },
};
