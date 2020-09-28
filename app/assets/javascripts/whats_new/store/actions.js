import * as types from './mutation_types';

export default {
  closeDrawer({ commit }) {
    commit(types.CLOSE_DRAWER);
  },
  openDrawer({ commit }, storageKey) {
    commit(types.OPEN_DRAWER);

    if (storageKey) {
      localStorage.setItem(storageKey, JSON.stringify(false));
    }
  },
};
