import * as types from './mutation_types';
import { normalizeMetrics, sortMetrics } from './utils';

export default {
  [types.REQUEST_METRICS_DATA](state) {
    state.emptyState = 'loading';
    state.showEmptyState = true;
  },
  [types.RECEIVE_METRICS_DATA_SUCCESS](state, groupData) {
    state.groups = groupData.map(group => ({
      ...group,
      metrics: normalizeMetrics(sortMetrics(group.metrics)),
    }));

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
  },
  [types.SET_GETTING_STARTED_EMPTY_STATE](state) {
    state.emptyState = 'gettingStarted';
  },
};
