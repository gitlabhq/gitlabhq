import Visibility from 'visibilityjs';
import axios from 'axios';
import { __ } from '../../../../locale';
import flash from '../../../../flash';
import Poll from '../../../../lib/utils/poll';
import service from '../../../services';
import { rightSidebarViews } from '../../../constants';
import * as types from './mutation_types';

let eTagPoll;

export const clearEtagPoll = () => {
  eTagPoll = null;
};
export const stopPipelinePolling = () => eTagPoll && eTagPoll.stop();
export const restartPipelinePolling = () => eTagPoll && eTagPoll.restart();

export const requestLatestPipeline = ({ commit }) => commit(types.REQUEST_LATEST_PIPELINE);
export const receiveLatestPipelineError = ({ commit, dispatch }) => {
  flash(__('There was an error loading latest pipeline'));
  commit(types.RECEIVE_LASTEST_PIPELINE_ERROR);
  dispatch('stopPipelinePolling');
};
export const receiveLatestPipelineSuccess = ({ rootGetters, commit }, { pipelines }) => {
  let lastCommitPipeline = false;

  if (pipelines && pipelines.length) {
    const lastCommitHash = rootGetters.lastCommit && rootGetters.lastCommit.id;
    lastCommitPipeline = pipelines.find(pipeline => pipeline.commit.id === lastCommitHash);
  }

  commit(types.RECEIVE_LASTEST_PIPELINE_SUCCESS, lastCommitPipeline);
};

export const fetchLatestPipeline = ({ dispatch, rootGetters }) => {
  if (eTagPoll) return;

  dispatch('requestLatestPipeline');

  eTagPoll = new Poll({
    resource: service,
    method: 'lastCommitPipelines',
    data: { getters: rootGetters },
    successCallback: ({ data }) => dispatch('receiveLatestPipelineSuccess', data),
    errorCallback: () => dispatch('receiveLatestPipelineError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      eTagPoll.restart();
    } else {
      eTagPoll.stop();
    }
  });
};

export const requestJobs = ({ commit }, id) => commit(types.REQUEST_JOBS, id);
export const receiveJobsError = ({ commit }, id) => {
  flash(__('There was an error loading jobs'));
  commit(types.RECEIVE_JOBS_ERROR, id);
};
export const receiveJobsSuccess = ({ commit }, { id, data }) =>
  commit(types.RECEIVE_JOBS_SUCCESS, { id, data });

export const fetchJobs = ({ dispatch }, stage) => {
  dispatch('requestJobs', stage.id);

  axios
    .get(stage.dropdownPath)
    .then(({ data }) => dispatch('receiveJobsSuccess', { id: stage.id, data }))
    .catch(() => dispatch('receiveJobsError', stage.id));
};

export const toggleStageCollapsed = ({ commit }, stageId) =>
  commit(types.TOGGLE_STAGE_COLLAPSE, stageId);

export const setDetailJob = ({ commit, dispatch }, job) => {
  commit(types.SET_DETAIL_JOB, job);
  dispatch('setRightPane', job ? rightSidebarViews.jobsDetail : rightSidebarViews.pipelines, {
    root: true,
  });
};

export const requestJobTrace = ({ commit }) => commit(types.REQUEST_JOB_TRACE);
export const receiveJobTraceError = ({ commit }) => {
  flash(__('Error fetching job trace'));
  commit(types.RECEIVE_JOB_TRACE_ERROR);
};
export const receiveJobTraceSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_JOB_TRACE_SUCCESS, data);

export const fetchJobTrace = ({ dispatch, state }) => {
  dispatch('requestJobTrace');

  return axios
    .get(`${state.detailJob.path}/trace`, { params: { format: 'json' } })
    .then(({ data }) => dispatch('receiveJobTraceSuccess', data))
    .catch(() => dispatch('receiveJobTraceError'));
};

export const resetLatestPipeline = ({ commit }) =>
  commit(types.RECEIVE_LASTEST_PIPELINE_SUCCESS, null);

export default () => {};
