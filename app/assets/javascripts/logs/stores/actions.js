import Api from '~/api';
import { backOff } from '~/lib/utils/common_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { s__ } from '~/locale';
import { convertToFixedRange } from '~/lib/utils/datetime_range';

import * as types from './mutation_types';

const flashTimeRangeWarning = () => {
  flash(s__('Metrics|Invalid time range, please verify.'), 'warning');
};

const flashLogsError = () => {
  flash(s__('Metrics|There was an error fetching the logs, please try again'));
};

const requestLogsUntilData = params =>
  backOff((next, stop) => {
    Api.getPodLogs(params)
      .then(res => {
        if (res.status === httpStatusCodes.ACCEPTED) {
          next();
          return;
        }
        stop(res);
      })
      .catch(err => {
        stop(err);
      });
  });

export const setInitData = ({ commit }, { timeRange, environmentName, podName }) => {
  if (timeRange) {
    commit(types.SET_TIME_RANGE, timeRange);
  }
  commit(types.SET_PROJECT_ENVIRONMENT, environmentName);
  commit(types.SET_CURRENT_POD_NAME, podName);
};

export const showPodLogs = ({ dispatch, commit }, podName) => {
  commit(types.SET_CURRENT_POD_NAME, podName);
  dispatch('fetchLogs');
};

export const setSearch = ({ dispatch, commit }, searchQuery) => {
  commit(types.SET_SEARCH, searchQuery);
  dispatch('fetchLogs');
};

export const setTimeRange = ({ dispatch, commit }, timeRange) => {
  commit(types.SET_TIME_RANGE, timeRange);
  dispatch('fetchLogs');
};

export const showEnvironment = ({ dispatch, commit }, environmentName) => {
  commit(types.SET_PROJECT_ENVIRONMENT, environmentName);
  commit(types.SET_CURRENT_POD_NAME, null);
  dispatch('fetchLogs');
};

export const fetchEnvironments = ({ commit, dispatch }, environmentsPath) => {
  commit(types.REQUEST_ENVIRONMENTS_DATA);

  axios
    .get(environmentsPath)
    .then(({ data }) => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, data.environments);
      dispatch('fetchLogs');
    })
    .catch(() => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_ERROR);
      flash(s__('Metrics|There was an error fetching the environments data, please try again'));
    });
};

export const fetchLogs = ({ commit, state }) => {
  const params = {
    environment: state.environments.options.find(({ name }) => name === state.environments.current),
    podName: state.pods.current,
    search: state.search,
  };

  if (state.timeRange.current) {
    try {
      const { start, end } = convertToFixedRange(state.timeRange.current);
      params.start = start;
      params.end = end;
    } catch {
      flashTimeRangeWarning();
    }
  }

  commit(types.REQUEST_PODS_DATA);
  commit(types.REQUEST_LOGS_DATA);

  return requestLogsUntilData(params)
    .then(({ data }) => {
      const { pod_name, pods, logs } = data;
      commit(types.SET_CURRENT_POD_NAME, pod_name);

      commit(types.RECEIVE_PODS_DATA_SUCCESS, pods);
      commit(types.RECEIVE_LOGS_DATA_SUCCESS, logs);
    })
    .catch(() => {
      commit(types.RECEIVE_PODS_DATA_ERROR);
      commit(types.RECEIVE_LOGS_DATA_ERROR);
      flashLogsError();
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
