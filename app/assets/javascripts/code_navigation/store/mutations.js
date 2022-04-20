import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_DATA](state, { blobs, definitionPathPrefix, wrapTextNodes }) {
    state.blobs = blobs;
    state.definitionPathPrefix = definitionPathPrefix;
    state.wrapTextNodes = wrapTextNodes;
  },
  [types.REQUEST_DATA](state) {
    state.loading = true;
  },
  [types.REQUEST_DATA_SUCCESS](state, { path, normalizedData }) {
    state.loading = false;
    state.data = { ...state.data, [path]: normalizedData };
  },
  [types.REQUEST_DATA_ERROR](state) {
    state.loading = false;
  },
  [types.SET_CURRENT_DEFINITION](state, { definition, position, blobPath }) {
    state.currentDefinition = definition;
    state.currentDefinitionPosition = position;
    state.currentBlobPath = blobPath;
  },
};
