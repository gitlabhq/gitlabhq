import * as types from './mutation_types';

export const setDrawer = ({ commit }, data) => {
  return commit(types.default.SET_DRAWER, data);
};
