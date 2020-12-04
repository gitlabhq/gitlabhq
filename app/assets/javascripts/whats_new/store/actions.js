import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

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
  fetchItems({ commit, state }, page) {
    if (state.fetching) {
      return false;
    }

    commit(types.SET_FETCHING, true);

    return axios
      .get('/-/whats_new', {
        params: {
          page,
        },
      })
      .then(({ data, headers }) => {
        commit(types.ADD_FEATURES, data);

        const normalizedHeaders = normalizeHeaders(headers);
        const { nextPage } = parseIntPagination(normalizedHeaders);
        commit(types.SET_PAGE_INFO, {
          nextPage,
        });
      })
      .finally(() => {
        commit(types.SET_FETCHING, false);
      });
  },
  setDrawerBodyHeight({ commit }, height) {
    commit(types.SET_DRAWER_BODY_HEIGHT, height);
  },
};
