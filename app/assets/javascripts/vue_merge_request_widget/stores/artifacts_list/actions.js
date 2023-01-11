import Visibility from 'visibilityjs';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';

import * as types from './mutation_types';

export const setEndpoint = ({ commit }, endpoint) => commit(types.SET_ENDPOINT, endpoint);

export const requestArtifacts = ({ commit }) => commit(types.REQUEST_ARTIFACTS);

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

export const fetchArtifacts = ({ state, dispatch }) => {
  dispatch('requestArtifacts');

  eTagPoll = new Poll({
    resource: {
      getArtifacts(endpoint) {
        return axios.get(endpoint);
      },
    },
    data: state.endpoint,
    method: 'getArtifacts',
    successCallback: ({ data, status }) => {
      dispatch('receiveArtifactsSuccess', {
        data,
        status,
      });
    },
    errorCallback: () => dispatch('receiveArtifactsError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  } else {
    axios
      .get(state.endpoint)
      .then(({ data, status }) => dispatch('receiveArtifactsSuccess', { data, status }))
      .catch(() => dispatch('receiveArtifactsError'));
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartPolling');
    } else {
      dispatch('stopPolling');
    }
  });
};

export const receiveArtifactsSuccess = ({ commit }, response) => {
  // With 204 we keep polling and don't update the state
  if (response.status === HTTP_STATUS_OK) {
    commit(types.RECEIVE_ARTIFACTS_SUCCESS, response.data);
  }
};

export const receiveArtifactsError = ({ commit }) => commit(types.RECEIVE_ARTIFACTS_ERROR);
