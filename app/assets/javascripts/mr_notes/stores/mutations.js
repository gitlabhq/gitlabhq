import types from './mutation_types';

export default {
  [types.SET_ACTIVE_TAB](state, tab) {
    Object.assign(state, { activeTab: tab });
  },
  [types.SET_ENDPOINTS](state, endpoints) {
    Object.assign(state, { endpoints });
  },
  [types.SET_MR_METADATA](state, metadata) {
    Object.assign(state, { mrMetadata: metadata });
  },
  [types.SET_FAILED_TO_LOAD_METADATA](state, value) {
    Object.assign(state, { failedToLoadMetadata: value });
  },
};
