import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

export default {
  [types.SET_USER_LISTS_OPTIONS](state, options = {}) {
    state.options = options;
  },
  [types.REQUEST_USER_LISTS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_USER_LISTS_SUCCESS](state, { data, headers }) {
    state.isLoading = false;
    state.hasError = false;
    state.userLists = data || [];

    const normalizedHeaders = normalizeHeaders(headers);
    const paginationInfo = parseIntPagination(normalizedHeaders);
    state.count = paginationInfo?.total ?? state.userLists.length;
    state.pageInfo = paginationInfo;
  },
  [types.RECEIVE_USER_LISTS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
  [types.REQUEST_DELETE_USER_LIST](state, list) {
    state.userLists = state.userLists.filter((l) => l !== list);
  },
  [types.RECEIVE_DELETE_USER_LIST_ERROR](state, { error, list }) {
    state.isLoading = false;
    state.hasError = false;
    state.alerts = [].concat(error.message);
    state.userLists = state.userLists.concat(list).sort((l1, l2) => l1.iid - l2.iid);
  },
  [types.RECEIVE_CLEAR_ALERT](state, index) {
    state.alerts.splice(index, 1);
  },
};
