import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import trackDashboardLoad from '../monitoring_tracking_helper';
import statusCodes from '../../lib/utils/http_status';
import { backOff } from '../../lib/utils/common_utils';
import { s__, sprintf } from '../../locale';

import { PROMETHEUS_TIMEOUT } from '../constants';

function backOffRequest(makeRequestCallback) {
  return backOff((next, stop) => {
    makeRequestCallback()
      .then(resp => {
        if (resp.status === statusCodes.NO_CONTENT) {
          next();
        } else {
          stop(resp);
        }
      })
      .catch(stop);
  }, PROMETHEUS_TIMEOUT);
}

export const setGettingStartedEmptyState = ({ commit }) => {
  commit(types.SET_GETTING_STARTED_EMPTY_STATE);
};

export const setEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_ENDPOINTS, endpoints);
};

export const setShowErrorBanner = ({ commit }, enabled) => {
  commit(types.SET_SHOW_ERROR_BANNER, enabled);
};

export const requestMetricsDashboard = ({ commit }) => {
  commit(types.REQUEST_METRICS_DATA);
};
export const receiveMetricsDashboardSuccess = ({ commit, dispatch }, { response, params }) => {
  commit(types.SET_ALL_DASHBOARDS, response.all_dashboards);
  commit(types.RECEIVE_METRICS_DATA_SUCCESS, response.dashboard.panel_groups);
  return dispatch('fetchPrometheusMetrics', params);
};
export const receiveMetricsDashboardFailure = ({ commit }, error) => {
  commit(types.RECEIVE_METRICS_DATA_FAILURE, error);
};

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

export const fetchMetricsData = ({ dispatch }, params) => dispatch('fetchDashboard', params);

export const fetchDashboard = ({ state, dispatch }, params) => {
  dispatch('requestMetricsDashboard');

  if (state.currentDashboard) {
    // eslint-disable-next-line no-param-reassign
    params.dashboard = state.currentDashboard;
  }

  return backOffRequest(() => axios.get(state.dashboardEndpoint, { params }))
    .then(resp => resp.data)
    .then(response => dispatch('receiveMetricsDashboardSuccess', { response, params }))
    .catch(e => {
      dispatch('receiveMetricsDashboardFailure', e);
      if (state.showErrorBanner) {
        if (e.response.data && e.response.data.message) {
          const { message } = e.response.data;
          createFlash(
            sprintf(
              s__('Metrics|There was an error while retrieving metrics. %{message}'),
              { message },
              false,
            ),
          );
        } else {
          createFlash(s__('Metrics|There was an error while retrieving metrics'));
        }
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

  commit(types.REQUEST_METRIC_RESULT, { metricId: metric.metric_id });

  return fetchPrometheusResult(metric.prometheus_endpoint_path, queryParams)
    .then(result => {
      commit(types.RECEIVE_METRIC_RESULT_SUCCESS, { metricId: metric.metric_id, result });
    })
    .catch(error => {
      commit(types.RECEIVE_METRIC_RESULT_ERROR, { metricId: metric.metric_id, error });
      // Continue to throw error so the dashboard can notify using createFlash
      throw error;
    });
};

export const fetchPrometheusMetrics = ({ state, commit, dispatch, getters }, params) => {
  commit(types.REQUEST_METRICS_DATA);

  const promises = [];
  state.dashboard.panel_groups.forEach(group => {
    group.panels.forEach(panel => {
      panel.metrics.forEach(metric => {
        promises.push(dispatch('fetchPrometheusMetric', { metric, params }));
      });
    });
  });

  return Promise.all(promises)
    .then(() => {
      const dashboardType = state.currentDashboard === '' ? 'default' : 'custom';
      trackDashboardLoad({
        label: `${dashboardType}_metrics_dashboard`,
        value: getters.metricsWithData().length,
      });
    })
    .catch(() => {
      createFlash(s__(`Metrics|There was an error while retrieving metrics`), 'warning');
    });
};

export const fetchDeploymentsData = ({ state, dispatch }) => {
  if (!state.deploymentsEndpoint) {
    return Promise.resolve([]);
  }
  return axios
    .get(state.deploymentsEndpoint)
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

/**
 * Set a new array of metrics to a panel group
 * @param {*} data An object containing
 *   - `key` with a unique panel key
 *   - `metrics` with the metrics array
 */
export const setPanelGroupMetrics = ({ commit }, data) => {
  commit(types.SET_PANEL_GROUP_METRICS, data);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
