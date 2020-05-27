import Poll from '~/lib/utils/poll';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';
import { MAX_REQUESTS } from '../constants';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import * as Sentry from '@sentry/browser';
import * as types from './mutation_types';

const allNodesPresent = (clusters, retryCount) => {
  /*
    Nodes are coming from external Kubernetes clusters.
    They may fail for reasons GitLab cannot control.
    MAX_REQUESTS will ensure this poll stops at some point.
  */
  return retryCount > MAX_REQUESTS || clusters.every(cluster => cluster.nodes != null);
};

export const fetchClusters = ({ state, commit }) => {
  let retryCount = 0;

  const poll = new Poll({
    resource: {
      fetchClusters: paginatedEndPoint => axios.get(paginatedEndPoint),
    },
    data: `${state.endpoint}?page=${state.page}`,
    method: 'fetchClusters',
    successCallback: ({ data, headers }) => {
      retryCount += 1;

      try {
        if (data.clusters) {
          const normalizedHeaders = normalizeHeaders(headers);
          const paginationInformation = parseIntPagination(normalizedHeaders);

          commit(types.SET_CLUSTERS_DATA, { data, paginationInformation });
          commit(types.SET_LOADING_STATE, false);

          if (allNodesPresent(data.clusters, retryCount)) {
            poll.stop();
          }
        }
      } catch (error) {
        poll.stop();

        Sentry.withScope(scope => {
          scope.setTag('javascript_clusters_list', 'fetchClustersSuccessCallback');
          Sentry.captureException(error);
        });
      }
    },
    errorCallback: response => {
      poll.stop();

      commit(types.SET_LOADING_STATE, false);
      flash(__('Clusters|An error occurred while loading clusters'));

      Sentry.withScope(scope => {
        scope.setTag('javascript_clusters_list', 'fetchClustersErrorCallback');
        Sentry.captureException(response);
      });
    },
  });

  poll.makeRequest();
};

export const setPage = ({ commit }, page) => {
  commit(types.SET_PAGE, page);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
