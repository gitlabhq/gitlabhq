import * as types from './mutation_types';

// eslint-disable-next-line import/prefer-default-export
export const push = ({ commit }, fullPath) => {
  commit(types.PUSH, fullPath);
};
