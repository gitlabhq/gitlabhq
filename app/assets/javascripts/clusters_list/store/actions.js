import * as Sentry from '@sentry/browser';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';
import { MAX_REQUESTS } from '../constants';
import * as types from './mutation_types';

const allNodesPresent = (clusters, retryCount) => {
  /*
    Nodes are coming from external Kubernetes clusters.
    They may fail for reasons GitLab cannot control.
    MAX_REQUESTS will ensure this poll stops at some point.
  */
  return retryCount > MAX_REQUESTS || clusters.every((cluster) => cluster.nodes != null);
};

export const reportSentryError = (_store, { error, tag }) => {
  Sentry.withScope((scope) => {
    scope.setTag('javascript_clusters_list', tag);
    Sentry.captureException(error);
  });
};

export const fetchClusters = ({ state, commit, dispatch }) => {
  let retryCount = 0;

  commit(types.SET_LOADING_NODES, true);

  const poll = new Poll({
    resource: {
      fetchClusters: (paginatedEndPoint) => axios.get(paginatedEndPoint),
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
          commit(types.SET_LOADING_CLUSTERS, false);

          if (allNodesPresent(data.clusters, retryCount)) {
            poll.stop();
            commit(types.SET_LOADING_NODES, false);
          }
        }
      } catch (error) {
        poll.stop();

        commit(types.SET_LOADING_CLUSTERS, false);
        commit(types.SET_LOADING_NODES, false);

        dispatch('reportSentryError', { error, tag: 'fetchClustersSuccessCallback' });
      }
    },
    errorCallback: (response) => {
      poll.stop();

      commit(types.SET_LOADING_CLUSTERS, false);
      commit(types.SET_LOADING_NODES, false);
      createFlash({
        message: __('Clusters|An error occurred while loading clusters'),
      });

      dispatch('reportSentryError', { error: response, tag: 'fetchClustersErrorCallback' });
    },
  });

  poll.makeRequest();
};

export const setPage = ({ commit }, page) => {
  commit(types.SET_PAGE, page);
};
