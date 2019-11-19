import service from '../../services';
import * as types from './mutation_types';
import createFlash from '~/flash';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';

let stackTracePoll;
let detailPoll;

const stopPolling = poll => {
  if (poll) poll.stop();
};

export function startPollingDetails({ commit }, endpoint) {
  detailPoll = new Poll({
    resource: service,
    method: 'getSentryData',
    data: { endpoint },
    successCallback: ({ data }) => {
      if (!data) {
        detailPoll.restart();
        return;
      }

      commit(types.SET_ERROR, data.error);
      commit(types.SET_LOADING, false);

      stopPolling(detailPoll);
    },
    errorCallback: () => {
      commit(types.SET_LOADING, false);
      createFlash(__('Failed to load error details from Sentry.'));
    },
  });

  detailPoll.makeRequest();
}

export function startPollingStacktrace({ commit }, endpoint) {
  stackTracePoll = new Poll({
    resource: service,
    method: 'getSentryData',
    data: { endpoint },
    successCallback: ({ data }) => {
      if (!data) {
        stackTracePoll.restart();
        return;
      }
      commit(types.SET_STACKTRACE_DATA, data.error);
      commit(types.SET_LOADING_STACKTRACE, false);

      stopPolling(stackTracePoll);
    },
    errorCallback: () => {
      commit(types.SET_LOADING_STACKTRACE, false);
      createFlash(__('Failed to load stacktrace.'));
    },
  });

  stackTracePoll.makeRequest();
}

export default () => {};
