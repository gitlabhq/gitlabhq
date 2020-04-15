import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_DATA](state, data) {
    Object.assign(state, data);
  },
  [types.COMMITS_AUTHORS](state, data) {
    state.commitsAuthors = data;
  },
};
