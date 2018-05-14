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
  [types.REQUEST_JOBS](state) {
    state.isLoadingJobs = true;
  },
  [types.RECEIVE_JOBS_ERROR](state) {
    state.isLoadingJobs = false;
  },
  [types.RECEIVE_JOBS_SUCCESS](state, jobs) {
    state.isLoadingJobs = false;

    state.stages = jobs.reduce((acc, job) => {
      let stage = acc.find(s => s.title === job.stage);

      if (!stage) {
        stage = {
          title: job.stage,
          jobs: [],
        };

        acc.push(stage);
      }

      stage.jobs = stage.jobs.concat({
        id: job.id,
        name: job.name,
        status: job.status,
        stage: job.stage,
        duration: job.duration,
      });

      return acc;
    }, state.stages);
  },
};
