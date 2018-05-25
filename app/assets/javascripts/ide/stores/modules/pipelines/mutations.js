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
      state.latestPipeline = pipeline;
      state.stages = pipeline.details.stages.map((stage, i) => {
        const foundStage = state.stages.find(s => s.id === i);
        return {
          ...stage,
          id: i,
          isCollapsed: foundStage ? foundStage.isCollapsed : false,
          isLoading: foundStage ? foundStage.isLoading : false,
          jobs: foundStage ? foundStage.jobs : [],
        };
      });
    }
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
