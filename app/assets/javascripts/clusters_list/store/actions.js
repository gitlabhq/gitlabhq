import Poll from '~/lib/utils/poll';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

export const fetchClusters = ({ state, commit }) => {
  const poll = new Poll({
    resource: {
      fetchClusters: paginatedEndPoint => axios.get(paginatedEndPoint),
    },
    data: `${state.endpoint}?page=${state.page}`,
    method: 'fetchClusters',
    successCallback: ({ data, headers }) => {
      if (data.clusters) {
        const normalizedHeaders = normalizeHeaders(headers);
        const paginationInformation = parseIntPagination(normalizedHeaders);

        commit(types.SET_CLUSTERS_DATA, { data, paginationInformation });
        commit(types.SET_LOADING_STATE, false);
        poll.stop();
      }
    },
    errorCallback: () => flash(__('An error occurred while loading clusters')),
  });

  poll.makeRequest();
};

export const setPage = ({ commit }, page) => {
  commit(types.SET_PAGE, page);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
