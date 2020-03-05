import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import Poll from '~/lib/utils/poll';
import axios from '~/lib/utils/axios_utils';
import Visibility from 'visibilityjs';
import flash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const fetchClusters = ({ state, commit }) => {
  const poll = new Poll({
    resource: {
      fetchClusters: endpoint => axios.get(endpoint),
    },
    data: state.endpoint,
    method: 'fetchClusters',
    successCallback: ({ data }) => {
      commit(types.SET_CLUSTERS_DATA, convertObjectPropsToCamelCase(data, { deep: true }));
      commit(types.SET_LOADING_STATE, false);
    },
    errorCallback: () => flash(__('An error occurred while loading clusters')),
  });

  if (!Visibility.hidden()) {
    poll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      poll.restart();
    } else {
      poll.stop();
    }
  });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
