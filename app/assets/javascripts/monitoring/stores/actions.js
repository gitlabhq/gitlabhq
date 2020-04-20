import * as Sentry from '@sentry/browser';
import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import {
  gqClient,
  parseEnvironmentsResponse,
  parseAnnotationsResponse,
  removeLeadingSlash,
} from './utils';
import trackDashboardLoad from '../monitoring_tracking_helper';
import getEnvironments from '../queries/getEnvironments.query.graphql';
import getAnnotations from '../queries/getAnnotations.query.graphql';
import statusCodes from '../../lib/utils/http_status';
import {
  backOff,
  convertObjectPropsToCamelCase,
  isFeatureFlagEnabled,
} from '../../lib/utils/common_utils';
import { s__, sprintf } from '../../locale';

import {
  PROMETHEUS_TIMEOUT,
  ENVIRONMENT_AVAILABLE_STATE,
  DEFAULT_DASHBOARD_PATH,
} from '../constants';

function prometheusMetricQueryParams(timeRange) {
  const { start, end } = convertToFixedRange(timeRange);

  const timeDiff = (new Date(end) - new Date(start)) / 1000;
  const minStep = 60;
  const queryDataPoints = 600;

  return {
    start_time: start,
    end_time: end,
    step: Math.max(minStep, Math.ceil(timeDiff / queryDataPoints)),
  };
}

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

function getPrometheusMetricResult(prometheusEndpoint, params) {
  return backOffRequest(() => axios.get(prometheusEndpoint, { params }))
    .then(res => res.data)
    .then(response => {
      if (response.status === 'error') {
        throw new Error(response.error);
      }

      return response.data.result;
    });
}

// Setup

export const setGettingStartedEmptyState = ({ commit }) => {
  commit(types.SET_GETTING_STARTED_EMPTY_STATE);
};

export const setInitialState = ({ commit }, initialState) => {
  commit(types.SET_INITIAL_STATE, initialState);
};

export const setTimeRange = ({ commit }, timeRange) => {
  commit(types.SET_TIME_RANGE, timeRange);
};

export const filterEnvironments = ({ commit, dispatch }, searchTerm) => {
  commit(types.SET_ENVIRONMENTS_FILTER, searchTerm);
  dispatch('fetchEnvironmentsData');
};

export const setShowErrorBanner = ({ commit }, enabled) => {
  commit(types.SET_SHOW_ERROR_BANNER, enabled);
};

// All Data

export const fetchData = ({ dispatch }) => {
  dispatch('fetchEnvironmentsData');
  dispatch('fetchDashboard');
  /**
   * Annotations data is not yet fetched. This will be
   * ready after the BE piece is implemented.
   * https://gitlab.com/gitlab-org/gitlab/-/issues/211330
   */
  if (isFeatureFlagEnabled('metricsDashboardAnnotations')) {
    dispatch('fetchAnnotations');
  }
};

// Metrics dashboard

export const fetchDashboard = ({ state, commit, dispatch }) => {
  dispatch('requestMetricsDashboard');

  const params = {};
  if (state.currentDashboard) {
    params.dashboard = state.currentDashboard;
  }

  return backOffRequest(() => axios.get(state.dashboardEndpoint, { params }))
    .then(resp => resp.data)
    .then(response => dispatch('receiveMetricsDashboardSuccess', { response }))
    .catch(error => {
      Sentry.captureException(error);

      commit(types.SET_ALL_DASHBOARDS, error.response?.data?.all_dashboards ?? []);
      dispatch('receiveMetricsDashboardFailure', error);

      if (state.showErrorBanner) {
        if (error.response.data && error.response.data.message) {
          const { message } = error.response.data;
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

export const requestMetricsDashboard = ({ commit }) => {
  commit(types.REQUEST_METRICS_DASHBOARD);
};
export const receiveMetricsDashboardSuccess = ({ commit, dispatch }, { response }) => {
  const { all_dashboards, dashboard, metrics_data } = response;

  commit(types.SET_ALL_DASHBOARDS, all_dashboards);
  commit(types.RECEIVE_METRICS_DASHBOARD_SUCCESS, dashboard);
  commit(types.SET_ENDPOINTS, convertObjectPropsToCamelCase(metrics_data));

  return dispatch('fetchDashboardData');
};
export const receiveMetricsDashboardFailure = ({ commit }, error) => {
  commit(types.RECEIVE_METRICS_DASHBOARD_FAILURE, error);
};

// Metrics

/**
 * Loads timeseries data: Prometheus data points and deployment data from the project
 * @param {Object} Vuex store
 */
export const fetchDashboardData = ({ state, dispatch, getters }) => {
  dispatch('fetchDeploymentsData');

  if (!state.timeRange) {
    createFlash(s__(`Metrics|Invalid time range, please verify.`), 'warning');
    return Promise.reject();
  }

  const defaultQueryParams = prometheusMetricQueryParams(state.timeRange);

  const promises = [];
  state.dashboard.panelGroups.forEach(group => {
    group.panels.forEach(panel => {
      panel.metrics.forEach(metric => {
        promises.push(dispatch('fetchPrometheusMetric', { metric, defaultQueryParams }));
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

/**
 * Returns list of metrics in data.result
 * {"status":"success", "data":{"resultType":"matrix","result":[]}}
 *
 * @param {metric} metric
 */
export const fetchPrometheusMetric = ({ commit }, { metric, defaultQueryParams }) => {
  const queryParams = { ...defaultQueryParams };
  if (metric.step) {
    queryParams.step = metric.step;
  }

  commit(types.REQUEST_METRIC_RESULT, { metricId: metric.metricId });

  return getPrometheusMetricResult(metric.prometheusEndpointPath, queryParams)
    .then(result => {
      commit(types.RECEIVE_METRIC_RESULT_SUCCESS, { metricId: metric.metricId, result });
    })
    .catch(error => {
      Sentry.captureException(error);

      commit(types.RECEIVE_METRIC_RESULT_FAILURE, { metricId: metric.metricId, error });
      // Continue to throw error so the dashboard can notify using createFlash
      throw error;
    });
};

// Deployments

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
    .catch(error => {
      Sentry.captureException(error);
      dispatch('receiveDeploymentsDataFailure');
      createFlash(s__('Metrics|There was an error getting deployment information.'));
    });
};
export const receiveDeploymentsDataSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS, data);
};
export const receiveDeploymentsDataFailure = ({ commit }) => {
  commit(types.RECEIVE_DEPLOYMENTS_DATA_FAILURE);
};

// Environments

export const fetchEnvironmentsData = ({ state, dispatch }) => {
  dispatch('requestEnvironmentsData');
  return gqClient
    .mutate({
      mutation: getEnvironments,
      variables: {
        projectPath: removeLeadingSlash(state.projectPath),
        search: state.environmentsSearchTerm,
        states: [ENVIRONMENT_AVAILABLE_STATE],
      },
    })
    .then(resp =>
      parseEnvironmentsResponse(resp.data?.project?.data?.environments, state.projectPath),
    )
    .then(environments => {
      if (!environments) {
        createFlash(
          s__('Metrics|There was an error fetching the environments data, please try again'),
        );
      }

      dispatch('receiveEnvironmentsDataSuccess', environments);
    })
    .catch(err => {
      Sentry.captureException(err);
      dispatch('receiveEnvironmentsDataFailure');
      createFlash(s__('Metrics|There was an error getting environments information.'));
    });
};
export const requestEnvironmentsData = ({ commit }) => {
  commit(types.REQUEST_ENVIRONMENTS_DATA);
};
export const receiveEnvironmentsDataSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, data);
};
export const receiveEnvironmentsDataFailure = ({ commit }) => {
  commit(types.RECEIVE_ENVIRONMENTS_DATA_FAILURE);
};

export const fetchAnnotations = ({ state, dispatch }) => {
  const { start } = convertToFixedRange(state.timeRange);
  const dashboardPath =
    state.currentDashboard === '' ? DEFAULT_DASHBOARD_PATH : state.currentDashboard;
  return gqClient
    .mutate({
      mutation: getAnnotations,
      variables: {
        projectPath: removeLeadingSlash(state.projectPath),
        environmentName: state.currentEnvironmentName,
        dashboardPath,
        startingFrom: start,
      },
    })
    .then(resp => resp.data?.project?.environments?.nodes?.[0].metricsDashboard?.annotations.nodes)
    .then(parseAnnotationsResponse)
    .then(annotations => {
      if (!annotations) {
        createFlash(s__('Metrics|There was an error fetching annotations. Please try again.'));
      }

      dispatch('receiveAnnotationsSuccess', annotations);
    })
    .catch(err => {
      Sentry.captureException(err);
      dispatch('receiveAnnotationsFailure');
      createFlash(s__('Metrics|There was an error getting annotations information.'));
    });
};

export const receiveAnnotationsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_ANNOTATIONS_SUCCESS, data);
export const receiveAnnotationsFailure = ({ commit }) => commit(types.RECEIVE_ANNOTATIONS_FAILURE);

// Dashboard manipulation

/**
 * Set a new array of metrics to a panel group
 * @param {*} data An object containing
 *   - `key` with a unique panel key
 *   - `metrics` with the metrics array
 */
export const setPanelGroupMetrics = ({ commit }, data) => {
  commit(types.SET_PANEL_GROUP_METRICS, data);
};

export const duplicateSystemDashboard = ({ state }, payload) => {
  const params = {
    dashboard: payload.dashboard,
    file_name: payload.fileName,
    branch: payload.branch,
    commit_message: payload.commitMessage,
  };

  return axios
    .post(state.dashboardsEndpoint, params)
    .then(response => response.data)
    .then(data => data.dashboard)
    .catch(error => {
      Sentry.captureException(error);

      const { response } = error;

      if (response && response.data && response.data.error) {
        throw sprintf(s__('Metrics|There was an error creating the dashboard. %{error}'), {
          error: response.data.error,
        });
      } else {
        throw s__('Metrics|There was an error creating the dashboard.');
      }
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
