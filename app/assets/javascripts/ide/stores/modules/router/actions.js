import * as types from './mutation_types';

export const push = ({ commit }, fullPath) => {
  commit(types.PUSH, fullPath);
};
