import Vue from 'vue';
import VueResource from 'vue-resource';
import Cookies from 'js-cookie';
import { handleLocationHash } from '~/lib/utils/common_utils';
import * as types from './mutation_types';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  DIFF_VIEW_COOKIE_NAME,
} from '../constants';

Vue.use(VueResource);

export const setEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_ENDPOINT, endpoint);
};

export const setLoadingState = ({ commit }, state) => {
  commit(types.SET_LOADING, state);
};

export const fetchDiffFiles = ({ state, commit }) => {
  commit(types.SET_LOADING, true);

  return Vue.http
    .get(state.endpoint)
    .then(res => res.json())
    .then(res => {
      commit(types.SET_LOADING, false);
      commit(types.SET_DIFF_FILES, res.diff_files);
      return Vue.nextTick();
    })
    .then(handleLocationHash);
};

export const setDiffViewType = ({ commit }, isParallel) => {
  const type = isParallel ? PARALLEL_DIFF_VIEW_TYPE : INLINE_DIFF_VIEW_TYPE;

  commit(types.SET_DIFF_VIEW_TYPE, type);
  Cookies.set(DIFF_VIEW_COOKIE_NAME, type);
};

export const showCommentForm = ({ commit }, params) => {
  commit(types.ADD_COMMENT_FORM_LINE, params);
};

export const cancelCommentForm = ({ commit }, params) => {
  commit(types.REMOVE_COMMENT_FORM_LINE, params);
};
