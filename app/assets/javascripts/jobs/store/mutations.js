import * as types from './mutation_types';

export default {
  [types.SET_JOB_ENDPOINT](state, endpoint) {
    state.jobEndpoint = endpoint;
  },

  [types.SET_TRACE_OPTIONS](state, options = {}) {
    state.traceEndpoint = options.pagePath;
    state.traceState = options.logState;
  },

  [types.HIDE_SIDEBAR](state) {
    state.isSidebarOpen = false;
  },
  [types.SHOW_SIDEBAR](state) {
    state.isSidebarOpen = true;
  },

  [types.RECEIVE_TRACE_SUCCESS](state, log) {
    if (log.state) {
      state.traceState = log.state;
    }

    if (log.append) {
      state.trace += log.html;
      state.traceSize += log.size;
    } else {
      // When the job still does not have a trace
      // the trace response will not have a defined
      // html or size. We keep the old value otherwise these
      // will be set to `undefined`
      state.trace = log.html || state.trace;
      state.traceSize = log.size || state.traceSize;
    }

    if (state.traceSize < log.total) {
      state.isTraceSizeVisible = true;
    } else {
      state.isTraceSizeVisible = false;
    }

    state.isTraceComplete = log.complete || state.isTraceComplete;
  },

  /**
   * Will remove loading animation
   */
  [types.STOP_POLLING_TRACE](state) {
    state.isTraceComplete = true;
  },

  /**
   * Will remove loading animation
   */
  [types.RECEIVE_TRACE_ERROR](state) {
    state.isTraceComplete = true;
  },

  [types.REQUEST_JOB](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_JOB_SUCCESS](state, job) {
    state.hasError = false;
    state.isLoading = false;
    state.job = job;

    state.stages =
      job.pipeline && job.pipeline.details && job.pipeline.details.stages
        ? job.pipeline.details.stages
        : [];

    /**
     * We only update it on the first request
     * The dropdown can be changed by the user
     * after the first request,
     * and we do not want to hijack that
     */
    if (state.selectedStage === '' && job.stage) {
      state.selectedStage = job.stage;
    }
  },
  [types.RECEIVE_JOB_ERROR](state) {
    state.isLoading = false;
    state.job = {};
    state.hasError = true;
  },

  [types.ENABLE_SCROLL_TOP](state) {
    state.isScrollTopDisabled = false;
  },
  [types.DISABLE_SCROLL_TOP](state) {
    state.isScrollTopDisabled = true;
  },
  [types.ENABLE_SCROLL_BOTTOM](state) {
    state.isScrollBottomDisabled = false;
  },
  [types.DISABLE_SCROLL_BOTTOM](state) {
    state.isScrollBottomDisabled = true;
  },
  [types.TOGGLE_SCROLL_ANIMATION](state, toggle) {
    state.isScrollingDown = toggle;
  },

  [types.TOGGLE_IS_SCROLL_IN_BOTTOM_BEFORE_UPDATING_TRACE](state, toggle) {
    state.isScrolledToBottomBeforeReceivingTrace = toggle;
  },

  [types.REQUEST_JOBS_FOR_STAGE](state, stage = {}) {
    state.isLoadingJobs = true;
    state.selectedStage = stage.name;
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
