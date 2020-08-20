import * as types from './mutation_types';

export default {
  closeDrawer({ commit }) {
    commit(types.CLOSE_DRAWER);
  },
  openDrawer({ commit }) {
    commit(types.OPEN_DRAWER);
  },
};
