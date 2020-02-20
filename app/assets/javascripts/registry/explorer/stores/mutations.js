import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

export default {
  [types.SET_INITIAL_STATE](state, config) {
    state.config = {
      ...config,
      isGroupPage: config.isGroupPage !== undefined,
    };
  },

  [types.SET_IMAGES_LIST_SUCCESS](state, images) {
    state.images = images;
  },

  [types.SET_TAGS_LIST_SUCCESS](state, tags) {
    state.tags = tags;
  },

  [types.SET_MAIN_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },

  [types.SET_PAGINATION](state, headers) {
    const normalizedHeaders = normalizeHeaders(headers);
    state.pagination = parseIntPagination(normalizedHeaders);
  },

  [types.SET_TAGS_PAGINATION](state, headers) {
    const normalizedHeaders = normalizeHeaders(headers);
    state.tagsPagination = parseIntPagination(normalizedHeaders);
  },
};
