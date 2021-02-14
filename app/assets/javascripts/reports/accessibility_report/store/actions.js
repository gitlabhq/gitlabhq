import Visibility from 'visibilityjs';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import * as types from './mutation_types';

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

export const setEndpoint = ({ commit }, endpoint) => commit(types.SET_ENDPOINT, endpoint);

/**
 * We need to poll the report endpoint while they are being parsed in the Backend.
 * This can take up to one minute.
 *
 * Poll.js will handle etag response.
 * While http status code is 204, it means it's parsing, and we'll keep polling
 * When http status code is 200, it means parsing is done, we can show the results & stop polling
 * When http status code is 500, it means parsing went wrong and we stop polling
 */
export const fetchReport = ({ state, dispatch, commit }) => {
  commit(types.REQUEST_REPORT);

  eTagPoll = new Poll({
    resource: {
      getReport(endpoint) {
        return axios.get(endpoint);
      },
    },
    data: state.endpoint,
    method: 'getReport',
    successCallback: ({ status, data }) => dispatch('receiveReportSuccess', { status, data }),
    errorCallback: () => dispatch('receiveReportError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  } else {
    axios
      .get(state.endpoint)
      .then(({ status, data }) => dispatch('receiveReportSuccess', { status, data }))
      .catch(() => dispatch('receiveReportError'));
  }

  Visibility.change(() => {
    if (!Visibility.hidden() && state.isLoading) {
      dispatch('restartPolling');
    } else {
      dispatch('stopPolling');
    }
  });
};

export const receiveReportSuccess = ({ commit, dispatch }, { status, data }) => {
  if (status === httpStatusCodes.OK) {
    commit(types.RECEIVE_REPORT_SUCCESS, data);
    // Stop polling since we have the information already parsed and it won't be changing
    dispatch('stopPolling');
  }
};

export const receiveReportError = ({ commit, dispatch }) => {
  commit(types.RECEIVE_REPORT_ERROR);
  dispatch('stopPolling');
};
