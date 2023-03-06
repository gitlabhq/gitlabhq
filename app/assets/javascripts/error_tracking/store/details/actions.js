import { createAlert } from '~/alert';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';
import service from '../../services';
import * as types from './mutation_types';

let stackTracePoll;

const stopPolling = (poll) => {
  if (poll) poll.stop();
};

export function startPollingStacktrace({ commit }, endpoint) {
  stackTracePoll = new Poll({
    resource: service,
    method: 'getSentryData',
    data: { endpoint },
    successCallback: ({ data }) => {
      if (!data) {
        return;
      }
      commit(types.SET_STACKTRACE_DATA, data.error);
      commit(types.SET_LOADING_STACKTRACE, false);

      stopPolling(stackTracePoll);
    },
    errorCallback: () => {
      commit(types.SET_LOADING_STACKTRACE, false);
      createAlert({
        message: __('Failed to load stacktrace.'),
      });
    },
  });

  stackTracePoll.makeRequest();
}
