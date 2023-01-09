import axios from 'axios';
import Visibility from 'visibilityjs';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';
import { rightSidebarViews } from '../../../constants';
import service from '../../../services';
import * as types from './mutation_types';

let eTagPoll;

export const clearEtagPoll = () => {
  eTagPoll = null;
};
export const stopPipelinePolling = () => {
  if (eTagPoll) eTagPoll.stop();
};
export const restartPipelinePolling = () => {
  if (eTagPoll) eTagPoll.restart();
};
export const forcePipelineRequest = () => {
  if (eTagPoll) eTagPoll.makeRequest();
};

export const requestLatestPipeline = ({ commit }) => commit(types.REQUEST_LATEST_PIPELINE);
export const receiveLatestPipelineError = ({ commit, dispatch }, err) => {
  if (err.status !== HTTP_STATUS_NOT_FOUND) {
    dispatch(
      'setErrorMessage',
      {
        text: __('An error occurred while fetching the latest pipeline.'),
        action: () =>
          dispatch('forcePipelineRequest').then(() =>
            dispatch('setErrorMessage', null, { root: true }),
          ),
        actionText: __('Please try again'),
        actionPayload: null,
      },
      { root: true },
    );
  }
  commit(types.RECEIVE_LASTEST_PIPELINE_ERROR);
  dispatch('stopPipelinePolling');
};
export const receiveLatestPipelineSuccess = ({ rootGetters, commit }, { pipelines }) => {
  let lastCommitPipeline = false;

  if (pipelines && pipelines.length) {
    const lastCommitHash = rootGetters.lastCommit && rootGetters.lastCommit.id;
    lastCommitPipeline = pipelines.find((pipeline) => pipeline.commit.id === lastCommitHash);
  }

  commit(types.RECEIVE_LASTEST_PIPELINE_SUCCESS, lastCommitPipeline);
};

export const fetchLatestPipeline = ({ commit, dispatch, rootGetters }) => {
  if (eTagPoll) return;

  if (!rootGetters.lastCommit) {
    commit(types.RECEIVE_LASTEST_PIPELINE_SUCCESS, null);
    dispatch('stopPipelinePolling');
    return;
  }

  dispatch('requestLatestPipeline');

  eTagPoll = new Poll({
    resource: service,
    method: 'lastCommitPipelines',
    data: { getters: rootGetters },
    successCallback: ({ data }) => dispatch('receiveLatestPipelineSuccess', data),
    errorCallback: (err) => dispatch('receiveLatestPipelineError', err),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartPipelinePolling');
    } else {
      dispatch('stopPipelinePolling');
    }
  });
};

export const requestJobs = ({ commit }, id) => commit(types.REQUEST_JOBS, id);
export const receiveJobsError = ({ commit, dispatch }, stage) => {
  dispatch(
    'setErrorMessage',
    {
      text: __('An error occurred while loading the pipelines jobs.'),
      action: (payload) =>
        dispatch('fetchJobs', payload).then(() =>
          dispatch('setErrorMessage', null, { root: true }),
        ),
      actionText: __('Please try again'),
      actionPayload: stage,
    },
    { root: true },
  );
  commit(types.RECEIVE_JOBS_ERROR, stage.id);
};
export const receiveJobsSuccess = ({ commit }, { id, data }) =>
  commit(types.RECEIVE_JOBS_SUCCESS, { id, data });

export const fetchJobs = ({ dispatch }, stage) => {
  dispatch('requestJobs', stage.id);

  return axios
    .get(stage.dropdownPath)
    .then(({ data }) => dispatch('receiveJobsSuccess', { id: stage.id, data }))
    .catch(() => dispatch('receiveJobsError', stage));
};

export const toggleStageCollapsed = ({ commit }, stageId) =>
  commit(types.TOGGLE_STAGE_COLLAPSE, stageId);

export const setDetailJob = ({ commit, dispatch }, job) => {
  commit(types.SET_DETAIL_JOB, job);
  dispatch('rightPane/open', job ? rightSidebarViews.jobsDetail : rightSidebarViews.pipelines, {
    root: true,
  });
};

export const requestJobLogs = ({ commit }) => commit(types.REQUEST_JOB_LOGS);
export const receiveJobLogsError = ({ commit, dispatch }) => {
  dispatch(
    'setErrorMessage',
    {
      text: __('An error occurred while fetching the job logs.'),
      action: () =>
        dispatch('fetchJobLogs').then(() => dispatch('setErrorMessage', null, { root: true })),
      actionText: __('Please try again'),
      actionPayload: null,
    },
    { root: true },
  );
  commit(types.RECEIVE_JOB_LOGS_ERROR);
};
export const receiveJobLogsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_JOB_LOGS_SUCCESS, data);

export const fetchJobLogs = ({ dispatch, state }) => {
  dispatch('requestJobLogs');

  // update trace endpoint once BE compeletes trace re-naming in #340626
  return axios
    .get(`${state.detailJob.path}/trace`, { params: { format: 'json' } })
    .then(({ data }) => dispatch('receiveJobLogsSuccess', data))
    .catch(() => dispatch('receiveJobLogsError'));
};

export const resetLatestPipeline = ({ commit }) => {
  commit(types.RECEIVE_LASTEST_PIPELINE_SUCCESS, null);
  commit(types.SET_DETAIL_JOB, null);
};
