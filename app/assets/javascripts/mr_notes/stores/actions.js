import axios from '~/lib/utils/axios_utils';

import types from './mutation_types';

export function setActiveTab({ commit }, tab) {
  commit(types.SET_ACTIVE_TAB, tab);
}

export function setEndpoints({ commit }, endpoints) {
  commit(types.SET_ENDPOINTS, endpoints);
}

export async function fetchMrMetadata({ state, commit }) {
  if (state.endpoints?.metadata) {
    commit(types.SET_FAILED_TO_LOAD_METADATA, false);
    try {
      const { data } = await axios.get(state.endpoints.metadata);
      commit(types.SET_MR_METADATA, data);
    } catch (error) {
      commit(types.SET_FAILED_TO_LOAD_METADATA, true);
    }
  }
}

export const toggleAllVisibleDiscussions = ({ getters, dispatch }) => {
  if (getters.isDiffsPage) {
    dispatch('diffs/toggleAllDiffDiscussions');
  } else {
    dispatch('toggleAllDiscussions');
  }
};
