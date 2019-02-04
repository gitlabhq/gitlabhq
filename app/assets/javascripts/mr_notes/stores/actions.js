import types from './mutation_types';

export default {
  setActiveTab({ commit }, tab) {
    commit(types.SET_ACTIVE_TAB, tab);
  },
};
