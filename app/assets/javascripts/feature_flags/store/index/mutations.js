import Vue from 'vue';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

const updateFlag = (state, flag) => {
  const index = state.featureFlags.findIndex(({ id }) => id === flag.id);
  Vue.set(state.featureFlags, index, flag);
};

const createPaginationInfo = (headers) => {
  let paginationInfo;
  if (Object.keys(headers).length) {
    const normalizedHeaders = normalizeHeaders(headers);
    paginationInfo = parseIntPagination(normalizedHeaders);
  } else {
    paginationInfo = headers;
  }
  return paginationInfo;
};

export default {
  [types.SET_FEATURE_FLAGS_OPTIONS](state, options = {}) {
    state.options = options;
  },
  [types.REQUEST_FEATURE_FLAGS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_FEATURE_FLAGS_SUCCESS](state, response) {
    state.isLoading = false;
    state.hasError = false;
    state.featureFlags = response.data.feature_flags || [];

    const paginationInfo = createPaginationInfo(response.headers);
    state.count = paginationInfo?.total ?? state.featureFlags.length;
    state.pageInfo = paginationInfo;
  },
  [types.RECEIVE_FEATURE_FLAGS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
  [types.REQUEST_ROTATE_INSTANCE_ID](state) {
    state.isRotating = true;
    state.hasRotateError = false;
  },
  [types.RECEIVE_ROTATE_INSTANCE_ID_SUCCESS](state, { data: { token } }) {
    state.isRotating = false;
    state.instanceId = token;
    state.hasRotateError = false;
  },
  [types.RECEIVE_ROTATE_INSTANCE_ID_ERROR](state) {
    state.isRotating = false;
    state.hasRotateError = true;
  },
  [types.UPDATE_FEATURE_FLAG](state, flag) {
    updateFlag(state, flag);
  },
  [types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS](state, data) {
    updateFlag(state, data);
  },
  [types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR](state, i) {
    const flag = state.featureFlags.find(({ id }) => i === id);
    updateFlag(state, { ...flag, active: !flag.active });
  },
  [types.RECEIVE_CLEAR_ALERT](state, index) {
    state.alerts.splice(index, 1);
  },
};
