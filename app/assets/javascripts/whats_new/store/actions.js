import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { STORAGE_KEY } from '../utils/notification';
import * as types from './mutation_types';

export default {
  closeDrawer({ commit }) {
    commit(types.CLOSE_DRAWER);
  },
  openDrawer({ commit }, versionDigest) {
    commit(types.OPEN_DRAWER);

    if (versionDigest) {
      localStorage.setItem(STORAGE_KEY, versionDigest);
    }
  },
  fetchItems({ commit, state }, { page, versionDigest } = { page: null, versionDigest: null }) {
    if (state.fetching) {
      return false;
    }

    commit(types.SET_FETCHING, true);

    const v = versionDigest;
    return axios
      .get('/-/whats_new', {
        params: {
          page,
          v,
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
