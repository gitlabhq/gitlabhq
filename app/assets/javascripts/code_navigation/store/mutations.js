import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_DATA](state, { projectPath, commitId, blobPath }) {
    state.projectPath = projectPath;
    state.commitId = commitId;
    state.blobPath = blobPath;
  },
  [types.REQUEST_DATA](state) {
    state.loading = true;
  },
  [types.REQUEST_DATA_SUCCESS](state, data) {
    state.loading = false;
    state.data = data;
  },
  [types.REQUEST_DATA_ERROR](state) {
    state.loading = false;
  },
  [types.SET_CURRENT_DEFINITION](state, { definition, position }) {
    state.currentDefinition = definition;
    state.currentDefinitionPosition = position;
  },
};
