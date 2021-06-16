import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { backOff } from '~/lib/utils/common_utils';
import statusCodes from '~/lib/utils/http_status';
import { __ } from '~/locale';
import { MAX_REQUESTS, CHECKING_INSTALLED, TIMEOUT } from '../constants';
import * as types from './mutation_types';

export const requestFunctionsLoading = ({ commit }) => commit(types.REQUEST_FUNCTIONS_LOADING);
export const receiveFunctionsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_FUNCTIONS_SUCCESS, data);
export const receiveFunctionsPartial = ({ commit }, data) =>
  commit(types.RECEIVE_FUNCTIONS_PARTIAL, data);
export const receiveFunctionsTimeout = ({ commit }, data) =>
  commit(types.RECEIVE_FUNCTIONS_TIMEOUT, data);
export const receiveFunctionsNoDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_FUNCTIONS_NODATA_SUCCESS, data);
export const receiveFunctionsError = ({ commit }, error) =>
  commit(types.RECEIVE_FUNCTIONS_ERROR, error);

export const receiveMetricsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_METRICS_SUCCESS, data);
export const receiveMetricsNoPrometheus = ({ commit }) =>
  commit(types.RECEIVE_METRICS_NO_PROMETHEUS);
export const receiveMetricsNoDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_METRICS_NODATA_SUCCESS, data);
export const receiveMetricsError = ({ commit }, error) =>
  commit(types.RECEIVE_METRICS_ERROR, error);

export const fetchFunctions = ({ dispatch }, { functionsPath }) => {
  let retryCount = 0;

  const functionsPartiallyFetched = (data) => {
    if (data.functions !== null && data.functions.length) {
      dispatch('receiveFunctionsPartial', data);
    }
  };

  dispatch('requestFunctionsLoading');

  backOff((next, stop) => {
    axios
      .get(functionsPath)
      .then((response) => {
        if (response.data.knative_installed === CHECKING_INSTALLED) {
          retryCount += 1;
          if (retryCount < MAX_REQUESTS) {
            functionsPartiallyFetched(response.data);
            next();
          } else {
            stop(TIMEOUT);
          }
        } else {
          stop(response.data);
        }
      })
      .catch(stop);
  })
    .then((data) => {
      if (data === TIMEOUT) {
        dispatch('receiveFunctionsTimeout');
        createFlash({
          message: __('Loading functions timed out. Please reload the page to try again.'),
        });
      } else if (data.functions !== null && data.functions.length) {
        dispatch('receiveFunctionsSuccess', data);
      } else {
        dispatch('receiveFunctionsNoDataSuccess', data);
      }
    })
    .catch((error) => {
      dispatch('receiveFunctionsError', error);
      createFlash({
        message: error,
      });
    });
};

export const fetchMetrics = ({ dispatch }, { metricsPath, hasPrometheus }) => {
  let retryCount = 0;

  if (!hasPrometheus) {
    dispatch('receiveMetricsNoPrometheus');
    return;
  }

  backOff((next, stop) => {
    axios
      .get(metricsPath)
      .then((response) => {
        if (response.status === statusCodes.NO_CONTENT) {
          retryCount += 1;
          if (retryCount < MAX_REQUESTS) {
            next();
          } else {
            dispatch('receiveMetricsNoDataSuccess');
            stop(null);
          }
        } else {
          stop(response.data);
        }
      })
      .catch(stop);
  })
    .then((data) => {
      if (data === null) {
        return;
      }

      const updatedMetric = data.metrics;
      const queries = data.metrics.queries.map((query) => ({
        ...query,
        result: query.result.map((result) => ({
          ...result,
          values: result.values.map(([timestamp, value]) => ({
            time: new Date(timestamp * 1000).toISOString(),
            value: Number(value),
          })),
        })),
      }));

      updatedMetric.queries = queries;
      dispatch('receiveMetricsSuccess', updatedMetric);
    })
    .catch((error) => {
      dispatch('receiveMetricsError', error);
      createFlash({
        message: error,
      });
    });
};
