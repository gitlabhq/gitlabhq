import Service from '../services';
import * as types from './mutation_types';
import createFlash from '~/flash';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';

let eTagPoll;

export function startPolling({ commit }, endpoint) {
  eTagPoll = new Poll({
    resource: Service,
    method: 'getErrorList',
    data: { endpoint },
    successCallback: ({ data }) => {
      if (!data) {
        return;
      }
      commit(types.SET_ERRORS, data.errors);
      commit(types.SET_EXTERNAL_URL, data.external_url);
      commit(types.SET_LOADING, false);
    },
    errorCallback: () => {
      commit(types.SET_LOADING, false);
      createFlash(__('Failed to load errors from Sentry'));
    },
  });

  eTagPoll.makeRequest();
}

export default () => {};
