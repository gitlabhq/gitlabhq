import Visibility from 'visibilityjs';
import axios from '../../../lib/utils/axios_utils';
import httpStatusCodes from '../../../lib/utils/http_status';
import Poll from '../../../lib/utils/poll';
import * as types from './mutation_types';

export const setPaths = ({ commit }, paths) => commit(types.SET_PATHS, paths);

export const requestReports = ({ commit }) => commit(types.REQUEST_REPORTS);

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

/**
 * We need to poll the reports endpoint while they are being parsed in the Backend.
 * This can take up to one minute.
 *
 * Poll.js will handle etag response.
 * While http status code is 204, it means it's parsing, and we'll keep polling
 * When http status code is 200, it means parsing is done, we can show the results & stop polling
 * When http status code is 500, it means parsing went wrong and we stop polling
 */
export const fetchReports = ({ state, dispatch }) => {
  dispatch('requestReports');

  eTagPoll = new Poll({
    resource: {
      getReports(endpoint) {
        return axios.get(endpoint);
      },
    },
    data: state.endpoint,
    method: 'getReports',
    successCallback: ({ data, status }) =>
      dispatch('receiveReportsSuccess', {
        data,
        status,
      }),
    errorCallback: () => dispatch('receiveReportsError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  } else {
    axios
      .get(state.endpoint)
      .then(({ data, status }) => dispatch('receiveReportsSuccess', { data, status }))
      .catch(() => dispatch('receiveReportsError'));
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartPolling');
    } else {
      dispatch('stopPolling');
    }
  });
};

export const receiveReportsSuccess = ({ commit }, response) => {
  // With 204 we keep polling and don't update the state
  if (response.status === httpStatusCodes.OK) {
    commit(types.RECEIVE_REPORTS_SUCCESS, response.data);
  }
};

export const receiveReportsError = ({ commit }) => commit(types.RECEIVE_REPORTS_ERROR);

export const openModal = ({ commit }, payload) => commit(types.SET_ISSUE_MODAL_DATA, payload);

export const closeModal = ({ commit }, payload) => commit(types.RESET_ISSUE_MODAL_DATA, payload);
