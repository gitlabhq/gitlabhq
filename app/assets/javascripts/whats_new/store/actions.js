import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';

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
  fetchItems({ commit }) {
    return axios.get('/-/whats_new').then(({ data }) => {
      commit(types.SET_FEATURES, data);
    });
  },
};
