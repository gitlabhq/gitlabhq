import * as types from './mutation_types';

export default {
  /** Search data */
  [types.SET_SEARCH](state, searchQuery) {
    state.search = searchQuery;
  },

  /** Time Range data */
  [types.SET_TIME_RANGE](state, timeRange) {
    state.timeRange.current = timeRange;
  },

  /** Environments data */
  [types.SET_PROJECT_ENVIRONMENT](state, environmentName) {
    state.environments.current = environmentName;
  },
  [types.REQUEST_ENVIRONMENTS_DATA](state) {
    state.environments.options = [];
    state.environments.isLoading = true;
  },
  [types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS](state, environmentOptions) {
    state.environments.options = environmentOptions;
    state.environments.isLoading = false;
  },
  [types.RECEIVE_ENVIRONMENTS_DATA_ERROR](state) {
    state.environments.options = [];
    state.environments.isLoading = false;
  },

  /** Logs data */
  [types.REQUEST_LOGS_DATA](state) {
    state.logs.lines = [];
    state.logs.isLoading = true;
    state.logs.isComplete = false;
  },
  [types.RECEIVE_LOGS_DATA_SUCCESS](state, lines) {
    state.logs.lines = lines;
    state.logs.isLoading = false;
    state.logs.isComplete = true;
  },
  [types.RECEIVE_LOGS_DATA_ERROR](state) {
    state.logs.lines = [];
    state.logs.isLoading = false;
    state.logs.isComplete = true;
  },

  /** Pods data */
  [types.SET_CURRENT_POD_NAME](state, podName) {
    state.pods.current = podName;
  },
  [types.REQUEST_PODS_DATA](state) {
    state.pods.options = [];
  },
  [types.RECEIVE_PODS_DATA_SUCCESS](state, podOptions) {
    state.pods.options = podOptions;
  },
  [types.RECEIVE_PODS_DATA_ERROR](state) {
    state.pods.options = [];
  },
};
