import Visibility from 'visibilityjs';
import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import { setFaviconOverlay, resetFavicon } from '~/lib/utils/common_utils';
import flash from '~/flash';
import { __ } from '~/locale';
import {
  canScroll,
  isScrolledToBottom,
  isScrolledToTop,
  isScrolledToMiddle,
  scrollDown,
  scrollUp,
} from '~/lib/utils/scroll_utils';

export const setJobEndpoint = ({ commit }, endpoint) => commit(types.SET_JOB_ENDPOINT, endpoint);
export const setTraceOptions = ({ commit }, options) => commit(types.SET_TRACE_OPTIONS, options);

export const hideSidebar = ({ commit }) => commit(types.HIDE_SIDEBAR);
export const showSidebar = ({ commit }) => commit(types.SHOW_SIDEBAR);

export const toggleSidebar = ({ dispatch, state }) => {
  if (state.isSidebarOpen) {
    dispatch('hideSidebar');
  } else {
    dispatch('showSidebar');
  }
};

let eTagPoll;

export const clearEtagPoll = () => {
  eTagPoll = null;
};

export const stopPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};

export const restartPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};

export const requestJob = ({ commit }) => commit(types.REQUEST_JOB);

export const fetchJob = ({ state, dispatch }) => {
  dispatch('requestJob');

  eTagPoll = new Poll({
    resource: {
      getJob(endpoint) {
        return axios.get(endpoint);
      },
    },
    data: state.jobEndpoint,
    method: 'getJob',
    successCallback: ({ data }) => dispatch('receiveJobSuccess', data),
    errorCallback: () => dispatch('receiveJobError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  } else {
    axios
      .get(state.jobEndpoint)
      .then(({ data }) => dispatch('receiveJobSuccess', data))
      .catch(() => dispatch('receiveJobError'));
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartPolling');
    } else {
      dispatch('stopPolling');
    }
  });
};

export const receiveJobSuccess = ({ commit }, data = {}) => {
  commit(types.RECEIVE_JOB_SUCCESS, data);

  if (data.status && data.status.favicon) {
    setFaviconOverlay(data.status.favicon);
  } else {
    resetFavicon();
  }
};
export const receiveJobError = ({ commit }) => {
  commit(types.RECEIVE_JOB_ERROR);
  flash(__('An error occurred while fetching the job.'));
  resetFavicon();
};

/**
 * Job's Trace
 */
export const scrollTop = ({ dispatch }) => {
  scrollUp();
  dispatch('toggleScrollButtons');
};

export const scrollBottom = ({ dispatch }) => {
  scrollDown();
  dispatch('toggleScrollButtons');
};

/**
 * Responsible for toggling the disabled state of the scroll buttons
 */
export const toggleScrollButtons = ({ dispatch }) => {
  if (canScroll()) {
    if (isScrolledToMiddle()) {
      dispatch('enableScrollTop');
      dispatch('enableScrollBottom');
    } else if (isScrolledToTop()) {
      dispatch('disableScrollTop');
      dispatch('enableScrollBottom');
    } else if (isScrolledToBottom()) {
      dispatch('disableScrollBottom');
      dispatch('enableScrollTop');
    }
  } else {
    dispatch('disableScrollBottom');
    dispatch('disableScrollTop');
  }
};

export const disableScrollBottom = ({ commit }) => commit(types.DISABLE_SCROLL_BOTTOM);
export const disableScrollTop = ({ commit }) => commit(types.DISABLE_SCROLL_TOP);
export const enableScrollBottom = ({ commit }) => commit(types.ENABLE_SCROLL_BOTTOM);
export const enableScrollTop = ({ commit }) => commit(types.ENABLE_SCROLL_TOP);

/**
 * While the automatic scroll down is active,
 * we show the scroll down button with an animation
 */
export const toggleScrollAnimation = ({ commit }, toggle) =>
  commit(types.TOGGLE_SCROLL_ANIMATION, toggle);

/**
 * Responsible to handle automatic scroll
 */
export const toggleScrollisInBottom = ({ commit }, toggle) => {
  commit(types.TOGGLE_IS_SCROLL_IN_BOTTOM_BEFORE_UPDATING_TRACE, toggle);
};

export const requestTrace = ({ commit }) => commit(types.REQUEST_TRACE);

let traceTimeout;
export const fetchTrace = ({ dispatch, state }) =>
  axios
    .get(`${state.traceEndpoint}/trace.json`, {
      params: { state: state.traceState },
    })
    .then(({ data }) => {
      dispatch('toggleScrollisInBottom', isScrolledToBottom());
      dispatch('receiveTraceSuccess', data);

      if (!data.complete) {
        traceTimeout = setTimeout(() => {
          dispatch('fetchTrace');
        }, 4000);
      } else {
        dispatch('stopPollingTrace');
      }
    })
    .catch(() => dispatch('receiveTraceError'));

export const stopPollingTrace = ({ commit }) => {
  commit(types.STOP_POLLING_TRACE);
  clearTimeout(traceTimeout);
};
export const receiveTraceSuccess = ({ commit }, log) => commit(types.RECEIVE_TRACE_SUCCESS, log);
export const receiveTraceError = ({ commit }) => {
  commit(types.RECEIVE_TRACE_ERROR);
  clearTimeout(traceTimeout);
  flash(__('An error occurred while fetching the job log.'));
};

/**
 * Jobs list on sidebar - depend on stages dropdown
 */
export const requestJobsForStage = ({ commit }, stage) =>
  commit(types.REQUEST_JOBS_FOR_STAGE, stage);

// On stage click, set selected stage + fetch job
export const fetchJobsForStage = ({ dispatch }, stage = {}) => {
  dispatch('requestJobsForStage', stage);

  axios
    .get(stage.dropdown_path, {
      params: {
        retried: 1,
      },
    })
    .then(({ data }) => {
      const retriedJobs = data.retried.map(job => Object.assign({}, job, { retried: true }));
      const jobs = data.latest_statuses.concat(retriedJobs);

      dispatch('receiveJobsForStageSuccess', jobs);
    })
    .catch(() => dispatch('receiveJobsForStageError'));
};
export const receiveJobsForStageSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_JOBS_FOR_STAGE_SUCCESS, data);
export const receiveJobsForStageError = ({ commit }) => {
  commit(types.RECEIVE_JOBS_FOR_STAGE_ERROR);
  flash(__('An error occurred while fetching the jobs.'));
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
