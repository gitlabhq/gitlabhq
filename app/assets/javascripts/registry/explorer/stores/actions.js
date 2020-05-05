import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import * as types from './mutation_types';
import {
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
  DEFAULT_PAGE,
  DEFAULT_PAGE_SIZE,
  FETCH_TAGS_LIST_ERROR_MESSAGE,
} from '../constants';
import { decodeAndParse } from '../utils';

export const setInitialState = ({ commit }, data) => commit(types.SET_INITIAL_STATE, data);
export const setShowGarbageCollectionTip = ({ commit }, data) =>
  commit(types.SET_SHOW_GARBAGE_COLLECTION_TIP, data);

export const receiveImagesListSuccess = ({ commit }, { data, headers }) => {
  commit(types.SET_IMAGES_LIST_SUCCESS, data);
  commit(types.SET_PAGINATION, headers);
};

export const receiveTagsListSuccess = ({ commit }, { data, headers }) => {
  commit(types.SET_TAGS_LIST_SUCCESS, data);
  commit(types.SET_TAGS_PAGINATION, headers);
};

export const requestImagesList = ({ commit, dispatch, state }, pagination = {}) => {
  commit(types.SET_MAIN_LOADING, true);
  const { page = DEFAULT_PAGE, perPage = DEFAULT_PAGE_SIZE } = pagination;

  return axios
    .get(state.config.endpoint, { params: { page, per_page: perPage } })
    .then(({ data, headers }) => {
      dispatch('receiveImagesListSuccess', { data, headers });
    })
    .catch(() => {
      createFlash(FETCH_IMAGES_LIST_ERROR_MESSAGE);
    })
    .finally(() => {
      commit(types.SET_MAIN_LOADING, false);
    });
};

export const requestTagsList = ({ commit, dispatch }, { pagination = {}, params }) => {
  commit(types.SET_MAIN_LOADING, true);
  const { tags_path } = decodeAndParse(params);

  const { page = DEFAULT_PAGE, perPage = DEFAULT_PAGE_SIZE } = pagination;
  return axios
    .get(tags_path, { params: { page, per_page: perPage } })
    .then(({ data, headers }) => {
      dispatch('receiveTagsListSuccess', { data, headers });
    })
    .catch(() => {
      createFlash(FETCH_TAGS_LIST_ERROR_MESSAGE);
    })
    .finally(() => {
      commit(types.SET_MAIN_LOADING, false);
    });
};

export const requestDeleteTag = ({ commit, dispatch, state }, { tag, params }) => {
  commit(types.SET_MAIN_LOADING, true);
  return axios
    .delete(tag.destroy_path)
    .then(() => {
      dispatch('setShowGarbageCollectionTip', true);
      return dispatch('requestTagsList', { pagination: state.tagsPagination, params });
    })
    .finally(() => {
      commit(types.SET_MAIN_LOADING, false);
    });
};

export const requestDeleteTags = ({ commit, dispatch, state }, { ids, params }) => {
  commit(types.SET_MAIN_LOADING, true);
  const { tags_path } = decodeAndParse(params);

  const url = tags_path.replace('?format=json', '/bulk_destroy');

  return axios
    .delete(url, { params: { ids } })
    .then(() => {
      dispatch('setShowGarbageCollectionTip', true);
      return dispatch('requestTagsList', { pagination: state.tagsPagination, params });
    })
    .finally(() => {
      commit(types.SET_MAIN_LOADING, false);
    });
};

export const requestDeleteImage = ({ commit }, image) => {
  commit(types.SET_MAIN_LOADING, true);
  return axios
    .delete(image.destroy_path)
    .then(() => {
      commit(types.UPDATE_IMAGE, { ...image, deleting: true });
    })
    .finally(() => {
      commit(types.SET_MAIN_LOADING, false);
    });
};

export default () => {};
