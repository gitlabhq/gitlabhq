import Visibility from 'visibilityjs';
import * as types from './mutation_types';
import axios from '../../lib/utils/axios_utils';
import Poll from '../../lib/utils/poll';
import {
  canScroll,
  isScrolledToBottom,
  isScrolledToTop,
  isScrolledToMiddle,
  scrollDown,
} from '../../lib/utils/scroll_utils';

import { setCiStatusFavicon } from '../../lib/utils/common_utils';
import flash from '../../flash';
import { __ } from '../../locale';

export const setJobEndpoint = ({ commit }, endpoint) => commit(types.SET_JOB_ENDPOINT, endpoint);
export const setTraceOptions = ({ commit }, options) => commit(types.SET_TRACE_OPTIONS, options);
export const setStagesEndpoint = ({ commit }, endpoint) =>
  commit(types.SET_STAGES_ENDPOINT, endpoint);
export const setJobsEndpoint = ({ commit }, endpoint) => commit(types.SET_JOBS_ENDPOINT, endpoint);

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

export const receiveJobSuccess = ({ commit }, data) => commit(types.RECEIVE_JOB_SUCCESS, data);
export const receiveJobError = ({ commit }) => {
  commit(types.RECEIVE_JOB_ERROR);
  flash(__('An error occurred while fetching the job.'));
};

/**
 * Job's Trace
 */
export const scrollTop = ({ commit, dispatch }) => {
  commit(types.SCROLL_TO_TOP);
  scrollUp();
  dispatch('toggleScrollButtons');
};

/**
 * Scrolls page to the bottom
 * Commits SCROLL_TO_BOTTOM mutation to toggle the hasBeenScrolled flag
 * Dispatches `toggleScrollButtons` to handle the disabled state of the scroll buttons
 */
export const scrollBottom = ({ commit, dispatch }) => {
  commit(types.SCROLL_TO_BOTTOM);
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

export const requestTrace = ({ commit }) => commit(types.REQUEST_TRACE);

let traceTimeout;
export const fetchTrace = ({ dispatch, state, commit }) => {
  dispatch('requestTrace');

  axios
    .get(`${state.traceEndpoint}/trace.json`, {
      params: { state: state.traceState },
    })
    .then(({ data }) => {
      // data = {
      //   id: 101741835,
      //   status: 'running',
      //   complete: false,
      //   html:
      //     'Running with gitlab-runner 11.4.0~beta.748.gcde4a2d1 (cde4a2d1)\u003cbr\u003e  on docker-auto-scale ed2dce3a\u003cbr\u003eUsing Docker executor with image docker:stable ...\u003cbr\u003eStarting service docker:stable-dind ...\u003cbr\u003ePulling docker image docker:stable-dind ...\u003cbr\u003eUsing docker image sha256:943cc2194c118472a134b2fee0bb7144c1c62ca415ff030d0cc00d43b81e29f7 for docker:stable-dind ...\u003cbr\u003eWaiting for services to be up and running...\u003cbr\u003ePulling docker image docker:stable ...\u003cbr\u003eUsing docker image sha256:321f2cfcc3432bf7c18ee541c4cc4402d48156c1c7150f76026a2d3772369e89 for docker:stable ...\u003cbr\u003e\u003cdiv class="hidden" data-action="start" data-timestamp="1537960287" data-section="prepare_script"\u003esection_start:1537960287:prepare_script\u003c/div\u003eRunning on runner-ed2dce3a-project-13083-concurrent-0 via runner-ed2dce3a-srm-1537960221-ff03f02a...\u003cbr\u003e\u003cdiv class="hidden" data-action="end" data-timestamp="1537960289" data-section="prepare_script"\u003esection_end:1537960289:prepare_script\u003c/div\u003e\u003cdiv class="hidden" data-action="start" data-timestamp="1537960289" data-section="get_sources"\u003esection_start:1537960289:get_sources\u003c/div\u003e\u003cspan class="term-fg-l-green term-bold"\u003eCloning repository for master with git depth set to 20...\u003c/span\u003e\u003cbr\u003eCloning into \'/builds/gitlab-org/gitlab-ce\'...\u003cbr\u003e\u003cspan class="term-fg-l-green term-bold"\u003eChecking out 6c3c76af as master...\u003c/span\u003e\u003cbr\u003e\u003cspan class="term-fg-l-green term-bold"\u003eSkipping Git submodules setup\u003c/span\u003e\u003cbr\u003e\u003cdiv class="hidden" data-action="end" data-timestamp="1537960301" data-section="get_sources"\u003esection_end:1537960301:get_sources\u003c/div\u003e\u003cdiv class="hidden" data-action="start" data-timestamp="1537960301" data-section="restore_cache"\u003esection_start:1537960301:restore_cache\u003c/div\u003e\u003cdiv class="hidden" data-action="end" data-timestamp="1537960303" data-section="restore_cache"\u003esection_end:1537960303:restore_cache\u003c/div\u003e\u003cdiv class="hidden" data-action="start" data-timestamp="1537960303" data-section="download_artifacts"\u003esection_start:1537960303:download_artifacts\u003c/div\u003e\u003cdiv class="hidden" data-action="end" data-timestamp="1537960304" data-section="download_artifacts"\u003esection_end:1537960304:download_artifacts\u003c/div\u003e\u003cdiv class="hidden" data-action="start" data-timestamp="1537960304" data-section="build_script"\u003esection_start:1537960304:build_script\u003c/div\u003e\u003cspan class="term-fg-l-green term-bold"\u003e$ export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed \'s/^\\([0-9]*\\)\\.\\([0-9]*\\).*/\\1-\\2-stable/\')\u003c/span\u003e\u003cbr\u003e\u003cspan class="term-fg-l-green term-bold"\u003e$ docker run --env SOURCE_CODE="$PWD" --volume "$PWD":/code --volume /var/run/docker.sock:/var/run/docker.sock "registry.gitlab.com/gitlab-org/security-products/codequality:$SP_VERSION" /code\u003c/span\u003e\u003cbr\u003eUnable to find image \'registry.gitlab.com/gitlab-org/security-products/codequality:11-3-stable\' locally\u003cbr\u003e11-3-stable: Pulling from gitlab-org/security-products/codequality\u003cbr\u003e911c6d0c7995: Pulling fs layer\u003cbr\u003eaff9b9c51076: Pulling fs layer\u003cbr\u003e9500841639b7: Pulling fs layer\u003cbr\u003ece7d9f10a155: Pulling fs layer\u003cbr\u003e0348d20deefe: Pulling fs layer\u003cbr\u003e1349cf012439: Pulling fs layer\u003cbr\u003e80d35bc2fcb0: Pulling fs layer\u003cbr\u003e32785dd38a36: Pulling fs layer\u003cbr\u003e5b14ec8e4612: Pulling fs layer\u003cbr\u003ece7d9f10a155: Waiting\u003cbr\u003e0348d20deefe: Waiting\u003cbr\u003e1349cf012439: Waiting\u003cbr\u003e80d35bc2fcb0: Waiting\u003cbr\u003e32785dd38a36: Waiting\u003cbr\u003e5b14ec8e4612: Waiting\u003cbr\u003e9500841639b7: Verifying Checksum\u003cbr\u003e9500841639b7: Download complete\u003cbr\u003eaff9b9c51076: Verifying Checksum\u003cbr\u003eaff9b9c51076: Download complete\u003cbr\u003e0348d20deefe: Verifying Checksum\u003cbr\u003e0348d20deefe: Download complete\u003cbr\u003e1349cf012439: Verifying Checksum\u003cbr\u003e1349cf012439: Download complete\u003cbr\u003e911c6d0c7995: Verifying Checksum\u003cbr\u003e911c6d0c7995: Download complete\u003cbr\u003e80d35bc2fcb0: Verifying Checksum\u003cbr\u003e80d35bc2fcb0: Download complete\u003cbr\u003e32785dd38a36: Verifying Checksum\u003cbr\u003e32785dd38a36: Download complete\u003cbr\u003e911c6d0c7995: Pull complete\u003cbr\u003eaff9b9c51076: Pull complete\u003cbr\u003e5b14ec8e4612: Verifying Checksum\u003cbr\u003e5b14ec8e4612: Download complete\u003cbr\u003e9500841639b7: Pull complete\u003cbr\u003ece7d9f10a155: Verifying Checksum\u003cbr\u003ece7d9f10a155: Download complete\u003cbr\u003ece7d9f10a155: Pull complete\u003cbr\u003e0348d20deefe: Pull complete\u003cbr\u003e1349cf012439: Pull complete\u003cbr\u003e80d35bc2fcb0: Pull complete\u003cbr\u003e32785dd38a36: Pull complete\u003cbr\u003e5b14ec8e4612: Pull complete\u003cbr\u003eDigest: sha256:140e9a52a1700dae0aef504b3daf9854de98588ac6a9e733c0fe6938f65220ad\u003cbr\u003eStatus: Downloaded newer image for registry.gitlab.com/gitlab-org/security-products/codequality:11-3-stable\u003cbr\u003eUnable to find image \'codeclimate/codeclimate:0.72.0\' locally\u003cbr\u003e0.72.0: Pulling from codeclimate/codeclimate\u003cbr\u003e2f3f3e5e133b: Pulling fs layer\u003cbr\u003e2654c654a6e7: Pulling fs layer\u003cbr\u003e412e64056adf: Pulling fs layer\u003cbr\u003ea3ed95caeb02: Pulling fs layer\u003cbr\u003eb34d109380af: Pulling fs layer\u003cbr\u003eef84039c747a: Pulling fs layer\u003cbr\u003e0b64161d56c4: Pulling fs layer\u003cbr\u003e532d14be51e6: Pulling fs layer\u003cbr\u003e8210184098e2: Pulling fs layer\u003cbr\u003ebd15a272ee53: Pulling fs layer\u003cbr\u003ed25d7915b947: Pulling fs layer\u003cbr\u003e4e198ced2ee0: Pulling fs layer\u003cbr\u003e5bcf14160dfc: Pulling fs layer\u003cbr\u003ef47a75dcba39: Pulling fs layer\u003cbr\u003ea3ed95caeb02: Waiting\u003cbr\u003eb34d109380af: Waiting\u003cbr\u003eef84039c747a: Waiting\u003cbr\u003e0b64161d56c4: Waiting\u003cbr\u003e532d14be51e6: Waiting\u003cbr\u003e8210184098e2: Waiting\u003cbr\u003ebd15a272ee53: Waiting\u003cbr\u003ed25d7915b947: Waiting\u003cbr\u003e4e198ced2ee0: Waiting\u003cbr\u003e5bcf14160dfc: Waiting\u003cbr\u003ef47a75dcba39: Waiting\u003cbr\u003e412e64056adf: Verifying Checksum\u003cbr\u003e412e64056adf: Download complete\u003cbr\u003e2f3f3e5e133b: Verifying Checksum\u003cbr\u003e2f3f3e5e133b: Download complete\u003cbr\u003e2654c654a6e7: Verifying Checksum\u003cbr\u003e2654c654a6e7: Download complete\u003cbr\u003ea3ed95caeb02: Verifying Checksum\u003cbr\u003ea3ed95caeb02: Download complete\u003cbr\u003eb34d109380af: Verifying Checksum\u003cbr\u003eb34d109380af: Download complete\u003cbr\u003e2f3f3e5e133b: Pull complete\u003cbr\u003eef84039c747a: Verifying Checksum\u003cbr\u003eef84039c747a: Download complete\u003cbr\u003e0b64161d56c4: Verifying Checksum\u003cbr\u003e0b64161d56c4: Download complete\u003cbr\u003e532d14be51e6: Verifying Checksum\u003cbr\u003e532d14be51e6: Download complete\u003cbr\u003e8210184098e2: Verifying Checksum\u003cbr\u003e8210184098e2: Download complete\u003cbr\u003ebd15a272ee53: Verifying Checksum\u003cbr\u003ebd15a272ee53: Download complete\u003cbr\u003ed25d7915b947: Verifying Checksum\u003cbr\u003ed25d7915b947: Download complete\u003cbr\u003e4e198ced2ee0: Verifying Checksum\u003cbr\u003e4e198ced2ee0: Download complete\u003cbr\u003ef47a75dcba39: Verifying Checksum\u003cbr\u003ef47a75dcba39: Download complete\u003cbr\u003e5bcf14160dfc: Verifying Checksum\u003cbr\u003e5bcf14160dfc: Download complete\u003cbr\u003e2654c654a6e7: Pull complete\u003cbr\u003e412e64056adf: Pull complete\u003cbr\u003ea3ed95caeb02: Pull complete\u003cbr\u003eb34d109380af: Pull complete\u003cbr\u003eef84039c747a: Pull complete\u003cbr\u003e0b64161d56c4: Pull complete\u003cbr\u003e532d14be51e6: Pull complete\u003cbr\u003e8210184098e2: Pull complete\u003cbr\u003ebd15a272ee53: Pull complete\u003cbr\u003ed25d7915b947: Pull complete\u003cbr\u003e4e198ced2ee0: Pull complete\u003cbr\u003e5bcf14160dfc: Pull complete\u003cbr\u003ef47a75dcba39: Pull complete\u003cbr\u003eDigest: sha256:c8afb8c2037f7b9c5c9ae198aff00b1cf80db11d3591fbe89dfb3c69192663f1\u003cbr\u003eStatus: Downloaded newer image for codeclimate/codeclimate:0.72.0\u003cbr\u003eWARNING: A new version (v0.78.1) is available. Upgrade instructions are available at: https://github.com/codeclimate/codeclimate#packages\u003cbr\u003e',
      //   state:
      //     'eyJvZmZzZXQiOjU2MTEsIm5fb3Blbl90YWdzIjowLCJmZ19jb2xvciI6bnVsbCwiYmdfY29sb3IiOm51bGwsInN0eWxlX21hc2siOjB9',
      //   append: false,
      //   truncated: false,
      //   offset: 0,
      //   size: 5611,
      //   total: 56110,
      // };

      if (!state.fetchingStatusFavicon) {
        dispatch('fetchFavicon');
      }

      dispatch('receiveTraceSuccess', data);
      commit(types.TOGGLE_IS_SCROLL_IN_BOTTOM, isScrolledToBottom())

      if (!data.complete) {
        traceTimeout = setTimeout(() => {
          dispatch('fetchTrace');
        }, 4000);
      } else {
        dispatch('stopPollingTrace');
        dispatch('toggleScrollAnimation', false);
      }
    })
    .catch(() => {
      dispatch('receiveTraceError')
    });
};

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

export const fetchFavicon = ({ state, dispatch }) => {
  dispatch('requestStatusFavicon');
  setCiStatusFavicon(`${state.traceEndpoint}/status.json`)
    .then(() => dispatch('receiveStatusFaviconSuccess'))
    .catch(() => dispatch('requestStatusFaviconError'));
};
export const requestStatusFavicon = ({ commit }) => commit(types.REQUEST_STATUS_FAVICON);
export const receiveStatusFaviconSuccess = ({ commit }) =>
  commit(types.RECEIVE_STATUS_FAVICON_SUCCESS);
export const requestStatusFaviconError = ({ commit }) => commit(types.RECEIVE_STATUS_FAVICON_ERROR);

/**
 * Stages dropdown on sidebar
 */
export const requestStages = ({ commit }) => commit(types.REQUEST_STAGES);
export const fetchStages = ({ state, dispatch }) => {
  dispatch('requestStages');

  axios
    .get(state.stagesEndpoint)
    .then(({ data }) => dispatch('receiveStagesSuccess', data))
    .catch(() => dispatch('receiveStagesError'));
};
export const receiveStagesSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_STAGES_SUCCESS, data);
export const receiveStagesError = ({ commit }) => {
  commit(types.RECEIVE_STAGES_ERROR);
  flash(__('An error occurred while fetching stages.'));
};

/**
 * Jobs list on sidebar - depend on stages dropdown
 */
export const requestJobsForStage = ({ commit }) => commit(types.REQUEST_JOBS_FOR_STAGE);
export const setSelectedStage = ({ commit }, stage) => commit(types.SET_SELECTED_STAGE, stage);

// On stage click, set selected stage + fetch job
export const fetchJobsForStage = ({ state, dispatch }, stage) => {
  dispatch('setSelectedStage', stage);
  dispatch('requestJobsForStage');

  axios
    .get(state.stageJobsEndpoint)
    .then(({ data }) => dispatch('receiveJobsForStageSuccess', data))
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
