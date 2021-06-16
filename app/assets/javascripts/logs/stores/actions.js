import axios from '~/lib/utils/axios_utils';
import { backOff } from '~/lib/utils/common_utils';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import httpStatusCodes from '~/lib/utils/http_status';
import { TOKEN_TYPE_POD_NAME, tracking, logExplorerOptions } from '../constants';
import trackLogs from '../logs_tracking_helper';

import * as types from './mutation_types';

const requestUntilData = (url, params) =>
  backOff((next, stop) => {
    axios
      .get(url, { params })
      .then((res) => {
        if (res.status === httpStatusCodes.ACCEPTED) {
          next();
          return;
        }
        stop(res);
      })
      .catch((err) => {
        stop(err);
      });
  });

const requestLogsUntilData = ({ commit, state }) => {
  const params = {};
  const type = logExplorerOptions.environments;
  const selectedObj = state[type].options.find(({ name }) => name === state[type].current);
  const path = selectedObj.logs_api_path;

  if (state.pods.current) {
    params.pod_name = state.pods.current;
  }
  if (state.search) {
    params.search = state.search;
  }
  if (state.timeRange.current) {
    try {
      const { start, end } = convertToFixedRange(state.timeRange.current);
      params.start_time = start;
      params.end_time = end;
    } catch {
      commit(types.SHOW_TIME_RANGE_INVALID_WARNING);
    }
  }
  if (state.logs.cursor) {
    params.cursor = state.logs.cursor;
  }

  return requestUntilData(path, params);
};

/**
 * Converts filters emitted by the component, e.g. a filterered-search
 * to parameters to be applied to the filters of the store
 * @param {Array} filters - List of strings or objects to filter by.
 * @returns {Object} - An object with `search` and `podName` keys.
 */
const filtersToParams = (filters = []) => {
  // Strings become part of the `search`
  const search = filters
    .filter((f) => typeof f === 'string')
    .join(' ')
    .trim();

  // null podName to show all pods
  const podName = filters.find((f) => f?.type === TOKEN_TYPE_POD_NAME)?.value?.data ?? null;

  return { search, podName };
};

export const setInitData = ({ commit }, { timeRange, environmentName, podName }) => {
  commit(types.SET_TIME_RANGE, timeRange);
  commit(types.SET_PROJECT_ENVIRONMENT, environmentName);
  commit(types.SET_CURRENT_POD_NAME, podName);
};

export const showFilteredLogs = ({ dispatch, commit }, filters = []) => {
  const { podName, search } = filtersToParams(filters);

  commit(types.SET_CURRENT_POD_NAME, podName);
  commit(types.SET_SEARCH, search);

  dispatch('fetchLogs', tracking.USED_SEARCH_BAR);
};

export const showPodLogs = ({ dispatch, commit }, podName) => {
  commit(types.SET_CURRENT_POD_NAME, podName);
  dispatch('fetchLogs', tracking.POD_LOG_CHANGED);
};

export const setTimeRange = ({ dispatch, commit }, timeRange) => {
  commit(types.SET_TIME_RANGE, timeRange);
  dispatch('fetchLogs', tracking.TIME_RANGE_SET);
};

export const showEnvironment = ({ dispatch, commit }, environmentName) => {
  commit(types.SET_PROJECT_ENVIRONMENT, environmentName);
  dispatch('fetchLogs', tracking.ENVIRONMENT_SELECTED);
};

export const refreshPodLogs = ({ dispatch, commit }) => {
  commit(types.REFRESH_POD_LOGS);
  dispatch('fetchLogs', tracking.REFRESH_POD_LOGS);
};

/**
 * Fetch environments data and initial logs
 * @param {Object} store
 * @param {String} environmentsPath
 */
export const fetchEnvironments = ({ commit, dispatch }, environmentsPath) => {
  commit(types.REQUEST_ENVIRONMENTS_DATA);

  return axios
    .get(environmentsPath)
    .then(({ data }) => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, data);
      dispatch('fetchLogs', tracking.ENVIRONMENT_SELECTED);
    })
    .catch(() => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_ERROR);
    });
};

export const fetchLogs = ({ commit, state }, trackingLabel) => {
  commit(types.REQUEST_LOGS_DATA);

  return requestLogsUntilData({ commit, state })
    .then(({ data }) => {
      const { pod_name, pods, logs, cursor } = data;
      if (logs && logs.length > 0) {
        trackLogs(trackingLabel);
      }
      commit(types.RECEIVE_LOGS_DATA_SUCCESS, { logs, cursor });
      commit(types.SET_CURRENT_POD_NAME, pod_name);
      commit(types.RECEIVE_PODS_DATA_SUCCESS, pods);
    })
    .catch(() => {
      commit(types.RECEIVE_PODS_DATA_ERROR);
      commit(types.RECEIVE_LOGS_DATA_ERROR);
    });
};

export const fetchMoreLogsPrepend = ({ commit, state }) => {
  if (state.logs.isComplete) {
    // return when all logs are loaded
    return Promise.resolve();
  }

  commit(types.REQUEST_LOGS_DATA_PREPEND);

  return requestLogsUntilData({ commit, state })
    .then(({ data }) => {
      const { logs, cursor } = data;
      commit(types.RECEIVE_LOGS_DATA_PREPEND_SUCCESS, { logs, cursor });
    })
    .catch(() => {
      commit(types.RECEIVE_LOGS_DATA_PREPEND_ERROR);
    });
};

export const dismissRequestEnvironmentsError = ({ commit }) => {
  commit(types.HIDE_REQUEST_ENVIRONMENTS_ERROR);
};

export const dismissRequestLogsError = ({ commit }) => {
  commit(types.HIDE_REQUEST_LOGS_ERROR);
};

export const dismissInvalidTimeRangeWarning = ({ commit }) => {
  commit(types.HIDE_TIME_RANGE_INVALID_WARNING);
};
