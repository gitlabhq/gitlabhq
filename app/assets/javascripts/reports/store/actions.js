import Visibility from 'visibilityjs';
import $ from 'jquery';
import axios from '../../lib/utils/axios_utils';
import Poll from '../../lib/utils/poll';
import * as types from './mutation_types';

export const setEndpoint = ({ commit }, endpoint) => commit(types.SET_ENDPOINT, endpoint);

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
    successCallback: ({ data }) => dispatch('receiveReportsSuccess', data),
    errorCallback: () => dispatch('receiveReportsError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartPolling');
    } else {
      dispatch('stopPolling');
    }
  });
};

export const receiveReportsSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_REPORTS_SUCCESS, response);

export const receiveReportsError = ({ commit }) => commit(types.RECEIVE_REPORTS_ERROR);

export const openModal = ({ dispatch }, payload) => {
  dispatch('setModalData', payload);

  $('#modal-mrwidget-reports').modal('show');
};

export const setModalData = ({ commit }, payload) => commit(types.SET_ISSUE_MODAL_DATA, payload);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
