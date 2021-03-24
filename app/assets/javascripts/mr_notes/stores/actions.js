import axios from '~/lib/utils/axios_utils';

import types from './mutation_types';

export function setActiveTab({ commit }, tab) {
  commit(types.SET_ACTIVE_TAB, tab);
}

export function setEndpoints({ commit }, endpoints) {
  commit(types.SET_ENDPOINTS, endpoints);
}

export function setMrMetadata({ commit }, metadata) {
  commit(types.SET_MR_METADATA, metadata);
}

export function fetchMrMetadata({ dispatch, state }) {
  if (state.endpoints?.metadata) {
    axios
      .get(state.endpoints.metadata)
      .then((response) => {
        dispatch('setMrMetadata', response.data);
      })
      .catch(() => {
        // https://gitlab.com/gitlab-org/gitlab/-/issues/324740
        // We can't even do a simple console warning here because
        // the pipeline will fail. However, the issue above will
        // eventually handle errors appropriately.
        // console.warn('Failed to load MR Metadata for the Overview tab.');
      });
  }
}
