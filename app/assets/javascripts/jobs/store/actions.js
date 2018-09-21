import Visibility from 'visibilityjs';
import * as types from './mutation_types';
import axios from '../../lib/utils/axios_utils';
import Poll from '../../lib/utils/poll';
import { setCiStatusFavicon } from '../../lib/utils/common_utils';
import flash from '../../flash';
import { __ } from '../../locale';

export const setJobEndpoint = ({ commit }, endpoint) => commit(types.SET_JOB_ENDPOINT, endpoint);
export const setTraceEndpoint = ({ commit }, endpoint) =>
  commit(types.SET_TRACE_ENDPOINT, endpoint);
export const setStagesEndpoint = ({ commit }, endpoint) =>
  commit(types.SET_STAGES_ENDPOINT, endpoint);
export const setJobsEndpoint = ({ commit }, endpoint) => commit(types.SET_JOBS_ENDPOINT, endpoint);

let eTagPoll;

export const clearEtagPoll = () => {
  eTagPoll = null;
};

export const stopPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};

export const restartPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};

export const requestJob = ({ commit }) => commit(types.REQUEST_JOB);

export const fetchJob = ({ state, dispatch }) => {
  dispatch('requestJob');

  eTagPoll = new Poll({
    resource: {
      getJob(endpoint) {
        return axios.get(endpoint);
      },
    },
    data: state.jobEndpoint,
    method: 'getJob',
    successCallback: ({ data }) => dispatch('receiveJobSuccess', data),
    errorCallback: () => dispatch('receiveJobError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  } else {
    axios
      .get(state.jobEndpoint)
      .then(({ data }) => dispatch('receiveJobSuccess', data))
      .catch(() => dispatch('receiveJobError'));
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartPolling');
    } else {
      dispatch('stopPolling');
    }
  });
};

export const receiveJobSuccess = ({ commit }, data) => commit(types.RECEIVE_JOB_SUCCESS, data);
export const receiveJobError = ({ commit }) => {
  commit(types.RECEIVE_JOB_ERROR);
  flash(__('An error occurred while fetching the job.'));
};

/**
 * Job's Trace
 */
export const scrollTop = ({ commit }) => {
  commit(types.SCROLL_TO_TOP);
  window.scrollTo({ top: 0 });
};

export const scrollBottom = ({ commit }) => {
  commit(types.SCROLL_TO_BOTTOM);
  window.scrollTo({ top: document.height });
};

export const requestTrace = ({ commit }) => commit(types.REQUEST_TRACE);

let traceTimeout;
export const fetchTrace = ({ dispatch, state }) => {
  dispatch('requestTrace');

  axios
    .get(`${state.traceEndpoint}/trace.json`, {
      params: { state: state.traceState },
    })
    .then(({ data }) => {
      if (!state.fetchingStatusFavicon) {
        dispatch('fetchFavicon');
      }
      dispatch('receiveTraceSuccess', data);

      if (!data.complete) {
        traceTimeout = setTimeout(() => {
          dispatch('fetchTrace');
        }, 4000);
      } else {
        dispatch('stopPollingTrace');
      }
    })
    .catch(() => dispatch('receiveTraceError'));
};
export const stopPollingTrace = ({ commit }) => {
  commit(types.STOP_POLLING_TRACE);
  clearTimeout(traceTimeout);
};
export const receiveTraceSuccess = ({ commit }, log) => commit(types.RECEIVE_TRACE_SUCCESS, log);
export const receiveTraceError = ({ commit }) => {
  commit(types.RECEIVE_TRACE_ERROR);
  clearTimeout(traceTimeout);
  flash(__('An error occurred while fetching the job log.'));
};

export const fetchFavicon = ({ state, dispatch }) => {
  dispatch('requestStatusFavicon');
  setCiStatusFavicon(`${state.pagePath}/status.json`)
    .then(() => dispatch('receiveStatusFaviconSuccess'))
    .catch(() => dispatch('requestStatusFaviconError'));
};
export const requestStatusFavicon = ({ commit }) => commit(types.REQUEST_STATUS_FAVICON);
export const receiveStatusFaviconSuccess = ({ commit }) =>
  commit(types.RECEIVE_STATUS_FAVICON_SUCCESS);
export const requestStatusFaviconError = ({ commit }) => commit(types.RECEIVE_STATUS_FAVICON_ERROR);

/**
 * Stages dropdown on sidebar
 */
export const requestStages = ({ commit }) => commit(types.REQUEST_STAGES);
export const fetchStages = ({ state, dispatch }) => {
  dispatch('requestStages');

  axios
    .get(state.stagesEndpoint)
    .then(({ data }) => dispatch('receiveStagesSuccess', data))
    .catch(() => dispatch('receiveStagesError'));
};
export const receiveStagesSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_STAGES_SUCCESS, data);
export const receiveStagesError = ({ commit }) => {
  commit(types.RECEIVE_STAGES_ERROR);
  flash(__('An error occurred while fetching stages.'));
};

/**
 * Jobs list on sidebar - depend on stages dropdown
 */
export const requestJobsForStage = ({ commit }) => commit(types.REQUEST_JOBS_FOR_STAGE);
export const setSelectedStage = ({ commit }, stage) => commit(types.SET_SELECTED_STAGE, stage);

// On stage click, set selected stage + fetch job
export const fetchJobsForStage = ({ state, dispatch }, stage) => {
  dispatch('setSelectedStage', stage);
  dispatch('requestJobsForStage');

  axios
    .get(state.stageJobsEndpoint)
    .then(({ data }) => dispatch('receiveJobsForStageSuccess', data))
    .catch(() => dispatch('receiveJobsForStageError'));
};
export const receiveJobsForStageSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_JOBS_FOR_STAGE_SUCCESS, data);
export const receiveJobsForStageError = ({ commit }) => {
  commit(types.RECEIVE_JOBS_FOR_STAGE_ERROR);
  flash(__('An error occurred while fetching the jobs.'));
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
