/* eslint-disable no-param-reassign */
import * as types from './mutation_types';

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
        status: pipeline.status,
      };
    }
  },
  [types.REQUEST_STAGES](state) {
    state.isLoadingJobs = true;
  },
  [types.RECEIVE_STAGES_ERROR](state) {
    state.isLoadingJobs = false;
  },
  [types.RECEIVE_STAGES_SUCCESS](state, stages) {
    state.isLoadingJobs = false;

    state.stages = stages.map((stage, i) => ({
      ...stage,
      id: i,
      isCollapsed: false,
      isLoading: false,
      jobs: [],
    }));
  },
  [types.REQUEST_JOBS](state, id) {
    state.stages = state.stages.reduce(
      (acc, stage) =>
        acc.concat({
          ...stage,
          isLoading: id === stage.id ? true : stage.isLoading,
        }),
      [],
    );
  },
  [types.RECEIVE_JOBS_ERROR](state, id) {
    state.stages = state.stages.reduce(
      (acc, stage) =>
        acc.concat({
          ...stage,
          isLoading: id === stage.id ? false : stage.isLoading,
        }),
      [],
    );
  },
  [types.RECEIVE_JOBS_SUCCESS](state, { id, data }) {
    state.stages = state.stages.reduce(
      (acc, stage) =>
        acc.concat({
          ...stage,
          isLoading: id === stage.id ? false : stage.isLoading,
          jobs: id === stage.id ? data.latest_statuses : stage.jobs,
        }),
      [],
    );
  },
};
