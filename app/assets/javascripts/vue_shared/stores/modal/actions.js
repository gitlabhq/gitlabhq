import * as types from './mutation_types'

export const hide = ({ commit }) => {
  commit(types.HIDE);
};

export const show = ({ commit }) => {
  commit(types.SHOW);
};
