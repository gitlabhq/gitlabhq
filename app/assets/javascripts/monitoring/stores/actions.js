import * as Sentry from '@sentry/browser';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import { convertObjectPropsToCamelCase } from '../../lib/utils/common_utils';
import { s__, sprintf } from '../../locale';
import { ENVIRONMENT_AVAILABLE_STATE, OVERVIEW_DASHBOARD_PATH, VARIABLE_TYPES } from '../constants';
import trackDashboardLoad from '../monitoring_tracking_helper';
import getAnnotations from '../queries/getAnnotations.query.graphql';
import getDashboardValidationWarnings from '../queries/getDashboardValidationWarnings.query.graphql';
import getEnvironments from '../queries/getEnvironments.query.graphql';
import { getDashboard, getPrometheusQueryData } from '../requests';

import * as types from './mutation_types';
import {
  gqClient,
  parseEnvironmentsResponse,
  parseAnnotationsResponse,
  removeLeadingSlash,
} from './utils';

const axiosCancelToken = axios.CancelToken;
let cancelTokenSource;

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

/**
 * Extract error messages from API or HTTP request errors.
 *
 * - API errors are in `error.response.data.message`
 * - HTTP (axios) errors are in `error.messsage`
 *
 * @param {Object} error
 * @returns {String} User friendly error message
 */
function extractErrorMessage(error) {
  const message = error?.response?.data?.message;
  return message ?? error.message;
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

export const setExpandedPanel = ({ commit }, { group, panel }) => {
  commit(types.SET_EXPANDED_PANEL, { group, panel });
};

export const clearExpandedPanel = ({ commit }) => {
  commit(types.SET_EXPANDED_PANEL, {
    group: null,
    panel: null,
  });
};

export const setCurrentDashboard = ({ commit }, { currentDashboard }) => {
  commit(types.SET_CURRENT_DASHBOARD, currentDashboard);
};

// All Data

/**
 * Fetch all dashboard data.
 *
 * @param {Object} store
 * @returns A promise that resolves when the dashboard
 * skeleton has been loaded.
 */
export const fetchData = ({ dispatch }) => {
  dispatch('fetchEnvironmentsData');
  dispatch('fetchDashboard');
  dispatch('fetchAnnotations');
};

// Metrics dashboard

export const fetchDashboard = ({ state, commit, dispatch, getters }) => {
  dispatch('requestMetricsDashboard');

  const params = {};
  if (getters.fullDashboardPath) {
    params.dashboard = getters.fullDashboardPath;
  }

  return getDashboard(state.dashboardEndpoint, params)
    .then((response) => {
      dispatch('receiveMetricsDashboardSuccess', { response });
      /**
       * After the dashboard is fetched, there can be non-blocking invalid syntax
       * in the dashboard file. This call will fetch such syntax warnings
       * and surface a warning on the UI. If the invalid syntax is blocking,
       * the `fetchDashboard` returns a 404 with error messages that are displayed
       * on the UI.
       */
      dispatch('fetchDashboardValidationWarnings');
    })
    .catch((error) => {
      Sentry.captureException(error);

      commit(types.SET_ALL_DASHBOARDS, error.response?.data?.all_dashboards ?? []);
      dispatch('receiveMetricsDashboardFailure', error);

      if (state.showErrorBanner) {
        if (error.response.data && error.response.data.message) {
          const { message } = error.response.data;
          createFlash({
            message: sprintf(
              s__('Metrics|There was an error while retrieving metrics. %{message}'),
              { message },
              false,
            ),
          });
        } else {
          createFlash({
            message: s__('Metrics|There was an error while retrieving metrics'),
          });
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
    createFlash({
      message: s__(`Metrics|Invalid time range, please verify.`),
      type: 'warning',
    });
    return Promise.reject();
  }

  // Time range params must be pre-calculated once for all metrics and options
  // A subsequent call, may calculate a different time range
  const defaultQueryParams = prometheusMetricQueryParams(state.timeRange);

  dispatch('fetchVariableMetricLabelValues', { defaultQueryParams });

  const promises = [];
  state.dashboard.panelGroups.forEach((group) => {
    group.panels.forEach((panel) => {
      panel.metrics.forEach((metric) => {
        promises.push(dispatch('fetchPrometheusMetric', { metric, defaultQueryParams }));
      });
    });
  });

  return Promise.all(promises)
    .then(() => {
      const dashboardType = getters.fullDashboardPath === '' ? 'default' : 'custom';
      trackDashboardLoad({
        label: `${dashboardType}_metrics_dashboard`,
        value: getters.metricsWithData().length,
      });
    })
    .catch(() => {
      createFlash({
        message: s__(`Metrics|There was an error while retrieving metrics`),
        type: 'warning',
      });
    });
};

/**
 * Returns list of metrics in data.result
 * {"status":"success", "data":{"resultType":"matrix","result":[]}}
 *
 * @param {metric} metric
 */
export const fetchPrometheusMetric = (
  { commit, state, getters },
  { metric, defaultQueryParams },
) => {
  let queryParams = { ...defaultQueryParams };
  if (metric.step) {
    queryParams.step = metric.step;
  }

  if (state.variables.length > 0) {
    queryParams = {
      ...queryParams,
      ...getters.getCustomVariablesParams,
    };
  }

  commit(types.REQUEST_METRIC_RESULT, { metricId: metric.metricId });

  return getPrometheusQueryData(metric.prometheusEndpointPath, queryParams)
    .then((data) => {
      commit(types.RECEIVE_METRIC_RESULT_SUCCESS, { metricId: metric.metricId, data });
    })
    .catch((error) => {
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
    .then((resp) => resp.data)
    .then((response) => {
      if (!response || !response.deployments) {
        createFlash({
          message: s__('Metrics|Unexpected deployment data response from prometheus endpoint'),
        });
      }

      dispatch('receiveDeploymentsDataSuccess', response.deployments);
    })
    .catch((error) => {
      Sentry.captureException(error);
      dispatch('receiveDeploymentsDataFailure');
      createFlash({
        message: s__('Metrics|There was an error getting deployment information.'),
      });
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
    .then((resp) =>
      parseEnvironmentsResponse(resp.data?.project?.data?.environments, state.projectPath),
    )
    .then((environments) => {
      if (!environments) {
        createFlash({
          message: s__(
            'Metrics|There was an error fetching the environments data, please try again',
          ),
        });
      }

      dispatch('receiveEnvironmentsDataSuccess', environments);
    })
    .catch((err) => {
      Sentry.captureException(err);
      dispatch('receiveEnvironmentsDataFailure');
      createFlash({
        message: s__('Metrics|There was an error getting environments information.'),
      });
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

export const fetchAnnotations = ({ state, dispatch, getters }) => {
  const { start } = convertToFixedRange(state.timeRange);
  const dashboardPath = getters.fullDashboardPath || OVERVIEW_DASHBOARD_PATH;
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
    .then(
      (resp) => resp.data?.project?.environments?.nodes?.[0].metricsDashboard?.annotations.nodes,
    )
    .then(parseAnnotationsResponse)
    .then((annotations) => {
      if (!annotations) {
        createFlash({
          message: s__('Metrics|There was an error fetching annotations. Please try again.'),
        });
      }

      dispatch('receiveAnnotationsSuccess', annotations);
    })
    .catch((err) => {
      Sentry.captureException(err);
      dispatch('receiveAnnotationsFailure');
      createFlash({
        message: s__('Metrics|There was an error getting annotations information.'),
      });
    });
};

export const receiveAnnotationsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_ANNOTATIONS_SUCCESS, data);
export const receiveAnnotationsFailure = ({ commit }) => commit(types.RECEIVE_ANNOTATIONS_FAILURE);

export const fetchDashboardValidationWarnings = ({ state, dispatch, getters }) => {
  /**
   * Normally, the overview dashboard won't throw any validation warnings.
   *
   * However, if a bug sneaks into the overview dashboard making it invalid,
   * this might come handy for our clients
   */
  const dashboardPath = getters.fullDashboardPath || OVERVIEW_DASHBOARD_PATH;
  return gqClient
    .mutate({
      mutation: getDashboardValidationWarnings,
      variables: {
        projectPath: removeLeadingSlash(state.projectPath),
        environmentName: state.currentEnvironmentName,
        dashboardPath,
      },
    })
    .then((resp) => resp.data?.project?.environments?.nodes?.[0]?.metricsDashboard)
    .then(({ schemaValidationWarnings } = {}) => {
      const hasWarnings = schemaValidationWarnings && schemaValidationWarnings.length !== 0;
      /**
       * The payload of the dispatch is a boolean, because at the moment a standard
       * warning message is shown instead of the warnings the BE returns
       */
      dispatch('receiveDashboardValidationWarningsSuccess', hasWarnings || false);
    })
    .catch((err) => {
      Sentry.captureException(err);
      dispatch('receiveDashboardValidationWarningsFailure');
      createFlash({
        message: s__(
          'Metrics|There was an error getting dashboard validation warnings information.',
        ),
      });
    });
};

export const receiveDashboardValidationWarningsSuccess = ({ commit }, hasWarnings) =>
  commit(types.RECEIVE_DASHBOARD_VALIDATION_WARNINGS_SUCCESS, hasWarnings);
export const receiveDashboardValidationWarningsFailure = ({ commit }) =>
  commit(types.RECEIVE_DASHBOARD_VALIDATION_WARNINGS_FAILURE);

// Dashboard manipulation

export const toggleStarredValue = ({ commit, state, getters }) => {
  const { selectedDashboard } = getters;

  if (state.isUpdatingStarredValue) {
    // Prevent repeating requests for the same change
    return;
  }
  if (!selectedDashboard) {
    return;
  }

  const method = selectedDashboard.starred ? 'DELETE' : 'POST';
  const url = selectedDashboard.user_starred_path;
  const newStarredValue = !selectedDashboard.starred;

  commit(types.REQUEST_DASHBOARD_STARRING);

  axios({
    url,
    method,
  })
    .then(() => {
      commit(types.RECEIVE_DASHBOARD_STARRING_SUCCESS, { selectedDashboard, newStarredValue });
    })
    .catch(() => {
      commit(types.RECEIVE_DASHBOARD_STARRING_FAILURE);
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

export const duplicateSystemDashboard = ({ state }, payload) => {
  const params = {
    dashboard: payload.dashboard,
    file_name: payload.fileName,
    branch: payload.branch,
    commit_message: payload.commitMessage,
  };

  return axios
    .post(state.dashboardsEndpoint, params)
    .then((response) => response.data)
    .then((data) => data.dashboard)
    .catch((error) => {
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

// Variables manipulation

export const updateVariablesAndFetchData = ({ commit, dispatch }, updatedVariable) => {
  commit(types.UPDATE_VARIABLE_VALUE, updatedVariable);

  return dispatch('fetchDashboardData');
};

export const fetchVariableMetricLabelValues = ({ state, commit }, { defaultQueryParams }) => {
  const { start_time, end_time } = defaultQueryParams;
  const optionsRequests = [];

  state.variables.forEach((variable) => {
    if (variable.type === VARIABLE_TYPES.metric_label_values) {
      const { prometheusEndpointPath, label } = variable.options;

      const optionsRequest = getPrometheusQueryData(prometheusEndpointPath, {
        start_time,
        end_time,
      })
        .then((data) => {
          commit(types.UPDATE_VARIABLE_METRIC_LABEL_VALUES, { variable, label, data });
        })
        .catch(() => {
          createFlash({
            message: sprintf(
              s__('Metrics|There was an error getting options for variable "%{name}".'),
              {
                name: variable.name,
              },
            ),
          });
        });
      optionsRequests.push(optionsRequest);
    }
  });

  return Promise.all(optionsRequests);
};

// Panel Builder

export const setPanelPreviewTimeRange = ({ commit }, timeRange) => {
  commit(types.SET_PANEL_PREVIEW_TIME_RANGE, timeRange);
};

export const fetchPanelPreview = ({ state, commit, dispatch }, panelPreviewYml) => {
  if (!panelPreviewYml) {
    return null;
  }

  commit(types.SET_PANEL_PREVIEW_IS_SHOWN, true);
  commit(types.REQUEST_PANEL_PREVIEW, panelPreviewYml);

  return axios
    .post(state.panelPreviewEndpoint, { panel_yaml: panelPreviewYml })
    .then(({ data }) => {
      commit(types.RECEIVE_PANEL_PREVIEW_SUCCESS, data);

      dispatch('fetchPanelPreviewMetrics');
    })
    .catch((error) => {
      commit(types.RECEIVE_PANEL_PREVIEW_FAILURE, extractErrorMessage(error));
    });
};

export const fetchPanelPreviewMetrics = ({ state, commit }) => {
  if (cancelTokenSource) {
    cancelTokenSource.cancel();
  }
  cancelTokenSource = axiosCancelToken.source();

  const defaultQueryParams = prometheusMetricQueryParams(state.panelPreviewTimeRange);

  state.panelPreviewGraphData.metrics.forEach((metric, index) => {
    commit(types.REQUEST_PANEL_PREVIEW_METRIC_RESULT, { index });

    const params = { ...defaultQueryParams };
    if (metric.step) {
      params.step = metric.step;
    }
    return getPrometheusQueryData(metric.prometheusEndpointPath, params, {
      cancelToken: cancelTokenSource.token,
    })
      .then((data) => {
        commit(types.RECEIVE_PANEL_PREVIEW_METRIC_RESULT_SUCCESS, { index, data });
      })
      .catch((error) => {
        Sentry.captureException(error);

        commit(types.RECEIVE_PANEL_PREVIEW_METRIC_RESULT_FAILURE, { index, error });
        // Continue to throw error so the panel builder can notify using createFlash
        throw error;
      });
  });
};
