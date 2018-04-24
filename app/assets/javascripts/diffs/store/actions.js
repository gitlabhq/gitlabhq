import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import Cookies from 'js-cookie';
import { handleLocationHash } from '~/lib/utils/common_utils';
import * as types from './mutation_types';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  DIFF_VIEW_COOKIE_NAME,
} from '../constants';

export const setEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_ENDPOINT, endpoint);
};

export const setLoadingState = ({ commit }, state) => {
  commit(types.SET_LOADING, state);
};

export const fetchDiffFiles = ({ state, commit }) => {
  commit(types.SET_LOADING, true);

  return axios
    .get(state.endpoint)
    .then(res => {
      commit(types.SET_LOADING, false);
      commit(types.SET_MERGE_REQUEST_DIFFS, res.data.merge_request_diffs);
      commit(types.SET_DIFF_FILES, res.data.diff_files);
      return Vue.nextTick();
    })
    .then(handleLocationHash);
};

export const setInlineDiffViewType = ({ commit }) => {
  commit(types.SET_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE);
  Cookies.set(DIFF_VIEW_COOKIE_NAME, INLINE_DIFF_VIEW_TYPE);
};

export const setParallelDiffViewType = ({ commit }) => {
  commit(types.SET_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE);

  Cookies.set(DIFF_VIEW_COOKIE_NAME, PARALLEL_DIFF_VIEW_TYPE);
};

export const showCommentForm = ({ commit }, params) => {
  commit(types.ADD_COMMENT_FORM_LINE, params);
};

export const cancelCommentForm = ({ commit }, params) => {
  commit(types.REMOVE_COMMENT_FORM_LINE, params);
};

export const loadMoreLines = ({ commit }, options) => {
  const { endpoint, params, lineNumbers, fileHash } = options;

  return axios.get(endpoint, { params }).then(res => {
    const contextLines = res.data || [];

    commit(types.ADD_CONTEXT_LINES, {
      lineNumbers,
      contextLines,
      params,
      fileHash,
    });
  });
};
