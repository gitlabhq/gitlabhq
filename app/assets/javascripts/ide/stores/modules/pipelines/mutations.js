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
    state.hasLoadedPipeline = true;

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
        const foundStage = state.stages.find((s) => s.id === i);
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
      state.latestPipeline = null;
    }
  },
  [types.REQUEST_JOBS](state, id) {
    state.stages = state.stages.map((stage) => ({
      ...stage,
      isLoading: stage.id === id ? true : stage.isLoading,
    }));
  },
  [types.RECEIVE_JOBS_ERROR](state, id) {
    state.stages = state.stages.map((stage) => ({
      ...stage,
      isLoading: stage.id === id ? false : stage.isLoading,
    }));
  },
  [types.RECEIVE_JOBS_SUCCESS](state, { id, data }) {
    state.stages = state.stages.map((stage) => ({
      ...stage,
      isLoading: stage.id === id ? false : stage.isLoading,
      jobs: stage.id === id ? data.latest_statuses.map(normalizeJob) : stage.jobs,
    }));
  },
  [types.TOGGLE_STAGE_COLLAPSE](state, id) {
    state.stages = state.stages.map((stage) => ({
      ...stage,
      isCollapsed: stage.id === id ? !stage.isCollapsed : stage.isCollapsed,
    }));
  },
  [types.SET_DETAIL_JOB](state, job) {
    state.detailJob = { ...job };
  },
  [types.REQUEST_JOB_LOGS](state) {
    state.detailJob.isLoading = true;
  },
  [types.RECEIVE_JOB_LOGS_ERROR](state) {
    state.detailJob.isLoading = false;
  },
  [types.RECEIVE_JOB_LOGS_SUCCESS](state, data) {
    state.detailJob.isLoading = false;
    state.detailJob.output = data.html;
  },
};
