import * as types from './mutation_types';

export default {
  [types.UPDATE_CI_CONFIG](state, content) {
    state.currentCiFileContent = content;
  },
  [types.UPDATE_AVAILABLE_STAGES](state, stages) {
    state.availableStages = stages || [];
  },
};
