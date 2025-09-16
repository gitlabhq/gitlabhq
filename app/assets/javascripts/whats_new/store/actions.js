import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import * as types from './mutation_types';

export default {
  closeDrawer({ commit }) {
    commit(types.CLOSE_DRAWER);
  },
  openDrawer({ commit }) {
    commit(types.OPEN_DRAWER);
  },
  fetchItems({ commit, state }, { page, versionDigest } = { page: null, versionDigest: null }) {
    if (state.fetching) {
      return false;
    }

    commit(types.SET_FETCHING, true);

    const v = versionDigest;
    return axios
      .get(joinPaths('/', gon.relative_url_root || '', '/-/whats_new'), {
        params: {
          page,
          v,
        },
      })
      .then(({ data, headers }) => {
        const featuresPerRelease = [{ releaseHeading: true, release: data[0]?.release }, ...data];
        commit(types.ADD_FEATURES, featuresPerRelease);

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
  setReadArticles({ commit }, readArticles) {
    commit(types.SET_READ_ARTICLES, readArticles);
  },
};
