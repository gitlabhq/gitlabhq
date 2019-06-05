import * as types from './mutation_types';
import { normalizeMetrics, sortMetrics } from './utils';

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
  [types.SET_ENDPOINTS](state, endpoints) {
    state.metricsEndpoint = endpoints.metricsEndpoint;
    state.environmentsEndpoint = endpoints.environmentsEndpoint;
    state.deploymentsEndpoint = endpoints.deploymentsEndpoint;
    state.dashboardEndpoint = endpoints.dashboardEndpoint;
  },
  [types.SET_DASHBOARD_ENABLED](state, enabled) {
    state.useDashboardEndpoint = enabled;
  },
  [types.SET_GETTING_STARTED_EMPTY_STATE](state) {
    state.emptyState = 'gettingStarted';
  },
};
