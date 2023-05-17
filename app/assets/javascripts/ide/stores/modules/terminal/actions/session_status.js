import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import * as messages from '../messages';
import * as types from '../mutation_types';
import { isEndingStatus } from '../utils';

export const pollSessionStatus = ({ state, dispatch, commit }) => {
  dispatch('stopPollingSessionStatus');
  dispatch('fetchSessionStatus');

  const interval = setInterval(() => {
    if (!state.session) {
      dispatch('stopPollingSessionStatus');
    } else {
      dispatch('fetchSessionStatus');
    }
  }, 5000);

  commit(types.SET_SESSION_STATUS_INTERVAL, interval);
};

export const stopPollingSessionStatus = ({ state, commit }) => {
  const { sessionStatusInterval } = state;

  if (!sessionStatusInterval) {
    return;
  }

  clearInterval(sessionStatusInterval);

  commit(types.SET_SESSION_STATUS_INTERVAL, 0);
};

export const receiveSessionStatusSuccess = ({ commit, dispatch }, data) => {
  const status = data && data.status;

  commit(types.SET_SESSION_STATUS, status);

  if (isEndingStatus(status)) {
    dispatch('killSession');
  }
};

export const receiveSessionStatusError = ({ dispatch }) => {
  createAlert({ message: messages.UNEXPECTED_ERROR_STATUS });
  dispatch('killSession');
};

export const fetchSessionStatus = ({ dispatch, state }) => {
  if (!state.session) {
    return;
  }

  const { showPath } = state.session;

  axios
    .get(showPath)
    .then(({ data }) => {
      dispatch('receiveSessionStatusSuccess', data);
    })
    .catch((error) => {
      dispatch('receiveSessionStatusError', error);
    });
};
