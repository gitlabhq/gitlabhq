import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import Api from '~/api';
import * as types from './mutation_types';
import {
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
  DEFAULT_PAGE,
  DEFAULT_PAGE_SIZE,
  FETCH_TAGS_LIST_ERROR_MESSAGE,
  FETCH_IMAGE_DETAILS_ERROR_MESSAGE,
} from '../constants/index';
import { pathGenerator } from '../utils';

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

export const requestImagesList = (
  { commit, dispatch, state },
  { pagination = {}, name = null } = {},
) => {
  commit(types.SET_MAIN_LOADING, true);
  const { page = DEFAULT_PAGE, perPage = DEFAULT_PAGE_SIZE } = pagination;

  return axios
    .get(state.config.endpoint, { params: { page, per_page: perPage, name } })
    .then(({ data, headers }) => {
      dispatch('receiveImagesListSuccess', { data, headers });
    })
    .catch(() => {
      createFlash({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
    })
    .finally(() => {
      commit(types.SET_MAIN_LOADING, false);
    });
};

export const requestTagsList = ({ commit, dispatch, state: { imageDetails } }, pagination = {}) => {
  commit(types.SET_MAIN_LOADING, true);
  const tagsPath = pathGenerator(imageDetails);

  const { page = DEFAULT_PAGE, perPage = DEFAULT_PAGE_SIZE } = pagination;
  return axios
    .get(tagsPath, { params: { page, per_page: perPage } })
    .then(({ data, headers }) => {
      dispatch('receiveTagsListSuccess', { data, headers });
    })
    .catch(() => {
      createFlash({ message: FETCH_TAGS_LIST_ERROR_MESSAGE });
    })
    .finally(() => {
      commit(types.SET_MAIN_LOADING, false);
    });
};

export const requestImageDetailsAndTagsList = ({ dispatch, commit }, id) => {
  commit(types.SET_MAIN_LOADING, true);
  return Api.containerRegistryDetails(id)
    .then(({ data }) => {
      commit(types.SET_IMAGE_DETAILS, data);
      dispatch('requestTagsList');
    })
    .catch(() => {
      createFlash({ message: FETCH_IMAGE_DETAILS_ERROR_MESSAGE });
      commit(types.SET_MAIN_LOADING, false);
    });
};

export const requestDeleteTag = ({ commit, dispatch, state }, { tag }) => {
  commit(types.SET_MAIN_LOADING, true);
  return axios
    .delete(tag.destroy_path)
    .then(() => {
      dispatch('setShowGarbageCollectionTip', true);

      return dispatch('requestTagsList', state.tagsPagination);
    })
    .finally(() => {
      commit(types.SET_MAIN_LOADING, false);
    });
};

export const requestDeleteTags = ({ commit, dispatch, state }, { ids }) => {
  commit(types.SET_MAIN_LOADING, true);

  const tagsPath = pathGenerator(state.imageDetails, '/bulk_destroy');

  return axios
    .delete(tagsPath, { params: { ids } })
    .then(() => {
      dispatch('setShowGarbageCollectionTip', true);
      return dispatch('requestTagsList', state.tagsPagination);
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
