import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import statusCodes from '../../lib/utils/http_status';
import { backOff } from '../../lib/utils/common_utils';
import { s__, __ } from '../../locale';

const MAX_REQUESTS = 3;

function backOffRequest(makeRequestCallback) {
  let requestCounter = 0;
  return backOff((next, stop) => {
    makeRequestCallback()
      .then(resp => {
        if (resp.status === statusCodes.NO_CONTENT) {
          requestCounter += 1;
          if (requestCounter < MAX_REQUESTS) {
            next();
          } else {
            stop(new Error(__('Failed to connect to the prometheus server')));
          }
        } else {
          stop(resp);
        }
      })
      .catch(stop);
  });
}

export const setGettingStartedEmptyState = ({ commit }) => {
  commit(types.SET_GETTING_STARTED_EMPTY_STATE);
};

export const setEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_ENDPOINTS, endpoints);
};

export const setFeatureFlags = (
  { commit },
  { prometheusEndpointEnabled, multipleDashboardsEnabled, additionalPanelTypesEnabled },
) => {
  commit(types.SET_DASHBOARD_ENABLED, prometheusEndpointEnabled);
  commit(types.SET_MULTIPLE_DASHBOARDS_ENABLED, multipleDashboardsEnabled);
  commit(types.SET_ADDITIONAL_PANEL_TYPES_ENABLED, additionalPanelTypesEnabled);
};

export const setShowErrorBanner = ({ commit }, enabled) => {
  commit(types.SET_SHOW_ERROR_BANNER, enabled);
};

export const requestMetricsDashboard = ({ commit }) => {
  commit(types.REQUEST_METRICS_DATA);
};
export const receiveMetricsDashboardSuccess = (
  { state, commit, dispatch },
  { response, params },
) => {
  if (state.multipleDashboardsEnabled) {
    commit(types.SET_ALL_DASHBOARDS, response.all_dashboards);
  }
  commit(types.RECEIVE_METRICS_DATA_SUCCESS, response.dashboard.panel_groups);
  dispatch('fetchPrometheusMetrics', params);
};
export const receiveMetricsDashboardFailure = ({ commit }, error) => {
  commit(types.RECEIVE_METRICS_DATA_FAILURE, error);
};

export const requestMetricsData = ({ commit }) => commit(types.REQUEST_METRICS_DATA);
export const receiveMetricsDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_METRICS_DATA_SUCCESS, data);
export const receiveMetricsDataFailure = ({ commit }, error) =>
  commit(types.RECEIVE_METRICS_DATA_FAILURE, error);
export const receiveDeploymentsDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS, data);
export const receiveDeploymentsDataFailure = ({ commit }) =>
  commit(types.RECEIVE_DEPLOYMENTS_DATA_FAILURE);
export const receiveEnvironmentsDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, data);
export const receiveEnvironmentsDataFailure = ({ commit }) =>
  commit(types.RECEIVE_ENVIRONMENTS_DATA_FAILURE);

export const fetchData = ({ dispatch }, params) => {
  dispatch('fetchMetricsData', params);
  dispatch('fetchDeploymentsData');
  dispatch('fetchEnvironmentsData');
};

export const fetchMetricsData = ({ state, dispatch }, params) => {
  if (state.useDashboardEndpoint) {
    return dispatch('fetchDashboard', params);
  }

  dispatch('requestMetricsData');

  return backOffRequest(() => axios.get(state.metricsEndpoint, { params }))
    .then(resp => resp.data)
    .then(response => {
      if (!response || !response.data || !response.success) {
        dispatch('receiveMetricsDataFailure', null);
        createFlash(s__('Metrics|Unexpected metrics data response from prometheus endpoint'));
      }
      dispatch('receiveMetricsDataSuccess', response.data);
    })
    .catch(error => {
      dispatch('receiveMetricsDataFailure', error);
      if (state.setShowErrorBanner) {
        createFlash(s__('Metrics|There was an error while retrieving metrics'));
      }
    });
};

export const fetchDashboard = ({ state, dispatch }, params) => {
  dispatch('requestMetricsDashboard');

  if (state.currentDashboard) {
    // eslint-disable-next-line no-param-reassign
    params.dashboard = state.currentDashboard;
  }

  return axios
    .get(state.dashboardEndpoint, { params })
    .then(resp => resp.data)
    .then(response => {
      dispatch('receiveMetricsDashboardSuccess', { response, params });
    })
    .catch(error => {
      dispatch('receiveMetricsDashboardFailure', error);
      if (state.setShowErrorBanner) {
        createFlash(s__('Metrics|There was an error while retrieving metrics'));
      }
    });
};

function fetchPrometheusResult(prometheusEndpoint, params) {
  return backOffRequest(() => axios.get(prometheusEndpoint, { params }))
    .then(res => res.data)
    .then(response => {
      if (response.status === 'error') {
        throw new Error(response.error);
      }

      return response.data.result;
    });
}

/**
 * Returns list of metrics in data.result
 * {"status":"success", "data":{"resultType":"matrix","result":[]}}
 *
 * @param {metric} metric
 */
export const fetchPrometheusMetric = ({ commit }, { metric, params }) => {
  const { start, end } = params;
  const timeDiff = (new Date(end) - new Date(start)) / 1000;

  const minStep = 60;
  const queryDataPoints = 600;
  const step = Math.max(minStep, Math.ceil(timeDiff / queryDataPoints));

  const queryParams = {
    start,
    end,
    step,
  };

  return fetchPrometheusResult(metric.prometheus_endpoint_path, queryParams).then(result => {
    commit(types.SET_QUERY_RESULT, { metricId: metric.metric_id, result });
  });
};

export const fetchPrometheusMetrics = ({ state, commit, dispatch }, params) => {
  commit(types.REQUEST_METRICS_DATA);

  const promises = [];
  state.groups.forEach(group => {
    group.panels.forEach(panel => {
      panel.metrics.forEach(metric => {
        promises.push(dispatch('fetchPrometheusMetric', { metric, params }));
      });
    });
  });

  return Promise.all(promises).then(() => {
    if (state.metricsWithData.length === 0) {
      commit(types.SET_NO_DATA_EMPTY_STATE);
    }
  });
};

export const fetchDeploymentsData = ({ state, dispatch }) => {
  if (!state.deploymentsEndpoint) {
    return Promise.resolve([]);
  }
  return backOffRequest(() => axios.get(state.deploymentsEndpoint))
    .then(resp => resp.data)
    .then(response => {
      if (!response || !response.deployments) {
        createFlash(s__('Metrics|Unexpected deployment data response from prometheus endpoint'));
      }

      dispatch('receiveDeploymentsDataSuccess', response.deployments);
    })
    .catch(() => {
      dispatch('receiveDeploymentsDataFailure');
      createFlash(s__('Metrics|There was an error getting deployment information.'));
    });
};

export const fetchEnvironmentsData = ({ state, dispatch }) => {
  if (!state.environmentsEndpoint) {
    return Promise.resolve([]);
  }
  return axios
    .get(state.environmentsEndpoint)
    .then(resp => resp.data)
    .then(response => {
      if (!response || !response.environments) {
        createFlash(
          s__('Metrics|There was an error fetching the environments data, please try again'),
        );
      }
      dispatch('receiveEnvironmentsDataSuccess', response.environments);
    })
    .catch(() => {
      dispatch('receiveEnvironmentsDataFailure');
      createFlash(s__('Metrics|There was an error getting environments information.'));
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
