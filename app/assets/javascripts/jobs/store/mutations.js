import * as types from './mutation_types';

export default {
  [types.REQUEST_STATUS_FAVICON](state) {
    state.fetchingStatusFavicon = true;
  },
  [types.RECEIVE_STATUS_FAVICON_SUCCESS](state) {
    state.fetchingStatusFavicon = false;
  },
  [types.RECEIVE_STATUS_FAVICON_ERROR](state) {
    state.fetchingStatusFavicon = false;
  },

  [types.RECEIVE_TRACE_SUCCESS](state, log) {
    if (log.state) {
      state.traceState = log.state;
    }

    if (log.append) {
      state.trace += log.html;
      state.traceSize += log.size;
    } else {
      state.trace = log.html;
      state.traceSize = log.size;
    }

    if (state.traceSize < log.total) {
      state.isTraceSizeVisible = true;
    } else {
      state.isTraceSizeVisible = false;
    }

    state.isTraceComplete = log.complete;
    state.hasTraceError = false;
  },
  [types.STOP_POLLING_TRACE](state) {
    state.isTraceComplete = true;
  },
  // todo_fl: check this.
  [types.RECEIVE_TRACE_ERROR](state) {
    state.isLoadingTrace = false;
    state.isTraceComplete = true;
    state.hasTraceError = true;
  },

  [types.REQUEST_JOB](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_JOB_SUCCESS](state, job) {
    state.isLoading = false;
    state.hasError = false;
    state.job = job;
  },
  [types.RECEIVE_JOB_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
    state.job = {};
  },

  [types.SCROLL_TO_TOP](state) {
    state.isTraceScrolledToBottom = false;
    state.hasBeenScrolled = true;
  },
  [types.SCROLL_TO_BOTTOM](state) {
    state.isTraceScrolledToBottom = true;
    state.hasBeenScrolled = true;
  },

  [types.REQUEST_STAGES](state) {
    state.isLoadingStages = true;
  },
  [types.RECEIVE_STAGES_SUCCESS](state, stages) {
    state.isLoadingStages = false;
    state.stages = stages;
  },
  [types.RECEIVE_STAGES_ERROR](state) {
    state.isLoadingStages = false;
    state.stages = [];
  },

  [types.REQUEST_JOBS_FOR_STAGE](state) {
    state.isLoadingJobs = true;
  },
  [types.RECEIVE_JOBS_FOR_STAGE_SUCCESS](state, jobs) {
    state.isLoadingJobs = false;
    state.jobs = jobs;
  },
  [types.RECEIVE_JOBS_FOR_STAGE_ERROR](state) {
    state.isLoadingJobs = false;
    state.jobs = [];
  },
};
