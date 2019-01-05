import * as types from './mutation_types';

export const open = ({ commit }, data) => {
  commit(types.OPEN, data);
};

export const close = ({ commit }) => {
  commit(types.CLOSE);
};

export const show = ({ commit }) => {
  commit(types.SHOW);
};

export const hide = ({ commit }) => {
  commit(types.HIDE);
};
