import axios from 'axios';
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

export const requestStages = ({ commit }) => commit(types.REQUEST_STAGES);
export const receiveStagesError = ({ commit }) => {
  flash(__('There was an error loading job stages'));
  commit(types.RECEIVE_STAGES_ERROR);
};
export const receiveStagesSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_STAGES_SUCCESS, data);

export const fetchStages = ({ dispatch, state, rootState }) => {
  dispatch('requestStages');

  Api.pipelineJobs(rootState.currentProjectId, state.latestPipeline.id)
    .then(({ data }) => dispatch('receiveStagesSuccess', data))
    .then(() => state.stages.forEach(stage => dispatch('fetchJobs', stage)))
    .catch(() => dispatch('receiveStagesError'));
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
    .get(stage.dropdown_path)
    .then(({ data }) => {
      dispatch('receiveJobsSuccess', { id: stage.id, data });
    })
    .catch(() => dispatch('receiveJobsError', stage.id));
};

export default () => {};
