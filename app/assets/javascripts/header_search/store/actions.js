import * as types from './mutation_types';

export const setSearch = ({ commit }, value) => {
  commit(types.SET_SEARCH, value);
};
