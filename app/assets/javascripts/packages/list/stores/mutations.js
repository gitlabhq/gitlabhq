import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { GROUP_PAGE_TYPE } from '../constants';
import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_STATE](state, config) {
    state.config = {
      ...config,
      isGroupPage: config.pageType === GROUP_PAGE_TYPE,
    };
  },

  [types.SET_PACKAGE_LIST_SUCCESS](state, packages) {
    state.packages = packages;
  },

  [types.SET_MAIN_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },

  [types.SET_PAGINATION](state, headers) {
    const normalizedHeaders = normalizeHeaders(headers);
    state.pagination = parseIntPagination(normalizedHeaders);
  },

  [types.SET_SORTING](state, sorting) {
    state.sorting = { ...state.sorting, ...sorting };
  },

  [types.SET_FILTER](state, filter) {
    state.filter = filter;
  },
};
