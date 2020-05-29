import * as types from '../mutation_types';

export const init = ({ dispatch }) => {
  dispatch('fetchConfigCheck');
  dispatch('fetchRunnersCheck');
};

export const hideSplash = ({ commit }) => {
  commit(types.HIDE_SPLASH);
};

export const setPaths = ({ commit }, paths) => {
  commit(types.SET_PATHS, paths);
};
