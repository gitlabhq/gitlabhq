import * as types from './mutation_types';
import { logLinesParser, checkJobHasLog } from './utils';

export default {
  [types.SET_JOB_LOG_OPTIONS](state, options = {}) {
    state.jobEndpoint = options.jobEndpoint;
    state.logEndpoint = options.logEndpoint;
    state.testReportSummaryUrl = options.testReportSummaryUrl;
    state.fullScreenAPIAvailable = options.fullScreenAPIAvailable;
  },

  [types.HIDE_SIDEBAR](state) {
    state.isSidebarOpen = false;
  },
  [types.SHOW_SIDEBAR](state) {
    state.isSidebarOpen = true;
  },

  [types.RECEIVE_JOB_LOG_SUCCESS](state, log = {}) {
    if (log.state) {
      state.jobLogState = log.state;
    }

    if (log.append) {
      if (log.lines) {
        const { sections, lines } = logLinesParser(log.lines, {
          currentLines: state.jobLog,
          currentSections: state.jobLogSections,
        });

        state.jobLog = lines;
        state.jobLogSections = sections;
      }
      state.jobLogSize += log.size;
    } else {
      // When the job still does not have a log
      // the job log response will not have a defined
      // html or size. We keep the old value otherwise these
      // will be set to `null`
      if (log.lines) {
        const { sections, lines } = logLinesParser(log.lines, {}, window.location.hash);

        state.jobLog = lines;
        state.jobLogSections = sections;
      }

      state.jobLogSize = log.size || state.jobLogSize;
    }

    if (state.jobLogSize < log.total) {
      state.isJobLogSizeVisible = true;
    } else {
      state.isJobLogSizeVisible = false;
    }

    state.isJobLogComplete = log.complete || state.isJobLogComplete;
  },

  [types.SET_JOB_LOG_TIMEOUT](state, id) {
    state.jobLogTimeout = id;
  },

  /**
   * Will remove loading animation
   */
  [types.STOP_POLLING_JOB_LOG](state) {
    state.isJobLogComplete = true;
  },

  /**
   * Instead of filtering the array of lines to find the one that must be updated
   * we use Vue.set to make this process more performant
   *
   * https://vuex.vuejs.org/guide/mutations.html#mutations-follow-vue-s-reactivity-rules
   * @param {Object} state
   * @param {Object} section
   */
  [types.TOGGLE_COLLAPSIBLE_LINE](state, section) {
    if (state.jobLogSections[section]) {
      state.jobLogSections[section].isClosed = !state.jobLogSections[section].isClosed;
    }
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

    if (!checkJobHasLog(state)) {
      state.job = {};
    }

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
  [types.RECEIVE_TEST_SUMMARY_SUCCESS](state, testSummary) {
    state.testSummary = testSummary;
  },
  [types.RECEIVE_TEST_SUMMARY_COMPLETE](state) {
    state.testSummaryComplete = true;
  },
  [types.ENTER_FULLSCREEN_SUCCESS](state) {
    state.fullScreenEnabled = true;
  },
  [types.EXIT_FULLSCREEN_SUCCESS](state) {
    state.fullScreenEnabled = false;
  },
  [types.FULL_SCREEN_CONTAINER_SET_UP](state, value) {
    state.fullScreenContainerSetUp = value;
  },
  [types.FULL_SCREEN_MODE_AVAILABLE_SUCCESS](state) {
    state.fullScreenModeAvailable = true;
  },
};
