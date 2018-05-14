import { __ } from '../../../../locale';
import Api from '../../../../api';
import flash from '../../../../flash';
import * as types from './mutation_types';

export const requestLatestPipeline = ({ commit }) => commit(types.REQUEST_LATEST_PIPELINE);
export const receiveLatestPipelineError = ({ commit }) => {
  flash(__('There was an error loading latest pipeline'));
  commit(types.RECEIVE_LASTEST_PIPELINE_ERROR);
};
export const receiveLatestPipelineSuccess = ({ commit }, pipeline) =>
  commit(types.RECEIVE_LASTEST_PIPELINE_SUCCESS, pipeline);

export const fetchLatestPipeline = ({ dispatch, rootState }, sha) => {
  dispatch('requestLatestPipeline');

  return Api.pipelines(rootState.currentProjectId, { sha, per_page: '1' })
    .then(({ data }) => {
      dispatch('receiveLatestPipelineSuccess', data.pop());
    })
    .catch(() => dispatch('receiveLatestPipelineError'));
};

export const requestJobs = ({ commit }) => commit(types.REQUEST_JOBS);
export const receiveJobsError = ({ commit }) => {
  flash(__('There was an error loading jobs'));
  commit(types.RECEIVE_JOBS_ERROR);
};
export const receiveJobsSuccess = ({ commit }, data) => commit(types.RECEIVE_JOBS_SUCCESS, data);

export const fetchJobs = ({ dispatch, state, rootState }) => {
  dispatch('requestJobs');

  Api.pipelineJobs(rootState.currentProjectId, state.latestPipeline.id)
    .then(({ data }) => {
      dispatch('receiveJobsSuccess', data);
    })
    .catch(() => dispatch('receiveJobsError'));
};

export default () => {};
