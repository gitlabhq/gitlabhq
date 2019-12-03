import Vue from 'vue';
import { slugify } from '~/lib/utils/text_utility';
import * as types from './mutation_types';
import { normalizeMetric, normalizeQueryResult } from './utils';

const normalizePanelMetrics = (metrics, defaultLabel) =>
  metrics.map(metric => ({
    ...normalizeMetric(metric),
    label: metric.label || defaultLabel,
  }));

export default {
  [types.REQUEST_METRICS_DATA](state) {
    state.emptyState = 'loading';
    state.showEmptyState = true;
  },
  [types.RECEIVE_METRICS_DATA_SUCCESS](state, groupData) {
    state.dashboard.panel_groups = groupData.map((group, i) => {
      const key = `${slugify(group.group || 'default')}-${i}`;
      let { panels = [] } = group;

      // each panel has metric information that needs to be normalized
      panels = panels.map(panel => ({
        ...panel,
        metrics: normalizePanelMetrics(panel.metrics, panel.y_label),
      }));

      return {
        ...group,
        panels,
        key,
      };
    });

    if (!state.dashboard.panel_groups.length) {
      state.emptyState = 'noData';
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

    /**
     * Search the dashboard state for a matching id
     */
    state.dashboard.panel_groups.forEach(group => {
      group.panels.forEach(panel => {
        panel.metrics.forEach(metric => {
          if (metric.metric_id === metricId) {
            state.metricsWithData.push(metricId);
            // ensure dates/numbers are correctly formatted for charts
            const normalizedResults = result.map(normalizeQueryResult);
            Vue.set(metric, 'result', Object.freeze(normalizedResults));
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
  [types.SET_GETTING_STARTED_EMPTY_STATE](state) {
    state.emptyState = 'gettingStarted';
  },
  [types.SET_NO_DATA_EMPTY_STATE](state) {
    state.showEmptyState = true;
    state.emptyState = 'noData';
  },
  [types.SET_ALL_DASHBOARDS](state, dashboards) {
    state.allDashboards = dashboards || [];
  },
  [types.SET_SHOW_ERROR_BANNER](state, enabled) {
    state.showErrorBanner = enabled;
  },
  [types.SET_PANEL_GROUP_METRICS](state, payload) {
    const panelGroup = state.dashboard.panel_groups.find(pg => payload.key === pg.key);
    panelGroup.panels = payload.panels;
  },
};
