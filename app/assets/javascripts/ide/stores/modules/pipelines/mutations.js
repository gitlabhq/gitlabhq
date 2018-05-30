/* eslint-disable no-param-reassign */
import * as types from './mutation_types';
import { normalizeJob } from './utils';

export default {
  [types.REQUEST_LATEST_PIPELINE](state) {
    state.isLoadingPipeline = true;
  },
  [types.RECEIVE_LASTEST_PIPELINE_ERROR](state) {
    state.isLoadingPipeline = false;
  },
  [types.RECEIVE_LASTEST_PIPELINE_SUCCESS](state, pipeline) {
    state.isLoadingPipeline = false;

    if (pipeline) {
      state.latestPipeline = {
        id: pipeline.id,
        path: pipeline.path,
        commit: pipeline.commit,
        details: {
          status: pipeline.details.status,
        },
        yamlError: pipeline.yaml_errors,
      };
      state.stages = pipeline.details.stages.map((stage, i) => {
        const foundStage = state.stages.find(s => s.id === i);
        return {
          id: i,
          dropdownPath: stage.dropdown_path,
          name: stage.name,
          status: stage.status,
          isCollapsed: foundStage ? foundStage.isCollapsed : false,
          isLoading: foundStage ? foundStage.isLoading : false,
          jobs: foundStage ? foundStage.jobs : [],
        };
      });
    } else {
      state.latestPipeline = false;
    }
  },
  [types.REQUEST_JOBS](state, id) {
    const stage = state.stages.find(s => s.id === id);
    stage.isLoading = true;
  },
  [types.RECEIVE_JOBS_ERROR](state, id) {
    const stage = state.stages.find(s => s.id === id);
    stage.isLoading = false;
  },
  [types.RECEIVE_JOBS_SUCCESS](state, { id, data }) {
    const stage = state.stages.find(s => s.id === id);
    stage.isLoading = false;
    stage.jobs = data.latest_statuses.map(normalizeJob);
  },
  [types.TOGGLE_STAGE_COLLAPSE](state, id) {
    const stage = state.stages.find(s => s.id === id);
    stage.isCollapsed = !stage.isCollapsed;
  },
};
