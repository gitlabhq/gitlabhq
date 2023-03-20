import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import * as terminalService from '../../../../services/terminals';
import { STARTING, STOPPING, STOPPED } from '../constants';
import * as messages from '../messages';
import * as types from '../mutation_types';

export const requestStartSession = ({ commit }) => {
  commit(types.SET_SESSION_STATUS, STARTING);
};

export const receiveStartSessionSuccess = ({ commit, dispatch }, data) => {
  commit(types.SET_SESSION, {
    id: data.id,
    status: data.status,
    showPath: data.show_path,
    cancelPath: data.cancel_path,
    retryPath: data.retry_path,
    terminalPath: data.terminal_path,
    proxyWebsocketPath: data.proxy_websocket_path,
    services: data.services,
  });

  dispatch('pollSessionStatus');
};

export const receiveStartSessionError = ({ dispatch }) => {
  createAlert({ message: messages.UNEXPECTED_ERROR_STARTING });
  dispatch('killSession');
};

export const startSession = ({ state, dispatch, rootGetters, rootState }) => {
  if (state.session && state.session.status === STARTING) {
    return;
  }

  const { currentProject } = rootGetters;
  const { currentBranchId } = rootState;

  dispatch('requestStartSession');

  terminalService
    .create(currentProject.path_with_namespace, currentBranchId)
    .then(({ data }) => {
      dispatch('receiveStartSessionSuccess', data);
    })
    .catch((error) => {
      dispatch('receiveStartSessionError', error);
    });
};

export const requestStopSession = ({ commit }) => {
  commit(types.SET_SESSION_STATUS, STOPPING);
};

export const receiveStopSessionSuccess = ({ dispatch }) => {
  dispatch('killSession');
};

export const receiveStopSessionError = ({ dispatch }) => {
  createAlert({ message: messages.UNEXPECTED_ERROR_STOPPING });
  dispatch('killSession');
};

export const stopSession = ({ state, dispatch }) => {
  const { cancelPath } = state.session;

  dispatch('requestStopSession');

  axios
    .post(cancelPath)
    .then(() => {
      dispatch('receiveStopSessionSuccess');
    })
    .catch((err) => {
      dispatch('receiveStopSessionError', err);
    });
};

export const killSession = ({ commit, dispatch }) => {
  dispatch('stopPollingSessionStatus');
  commit(types.SET_SESSION_STATUS, STOPPED);
};

export const restartSession = ({ state, dispatch, rootState }) => {
  const { status, retryPath } = state.session;
  const { currentBranchId } = rootState;

  if (status !== STOPPED) {
    return;
  }

  if (!retryPath) {
    dispatch('startSession');
    return;
  }

  dispatch('requestStartSession');

  axios
    .post(retryPath, { branch: currentBranchId, format: 'json' })
    .then(({ data }) => {
      dispatch('receiveStartSessionSuccess', data);
    })
    .catch((error) => {
      const responseStatus = error.response && error.response.status;
      // We may have removed the build, in this case we'll just create a new session
      if (
        responseStatus === HTTP_STATUS_NOT_FOUND ||
        responseStatus === HTTP_STATUS_UNPROCESSABLE_ENTITY
      ) {
        dispatch('startSession');
      } else {
        dispatch('receiveStartSessionError', error);
      }
    });
};
