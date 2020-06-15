import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders, parseBoolean } from '~/lib/utils/common_utils';
import { IMAGE_DELETE_SCHEDULED_STATUS, IMAGE_FAILED_DELETED_STATUS } from '../constants/index';

export default {
  [types.SET_INITIAL_STATE](state, config) {
    state.config = {
      ...config,
      expirationPolicy: config.expirationPolicy ? JSON.parse(config.expirationPolicy) : undefined,
      isGroupPage: parseBoolean(config.isGroupPage),
      isAdmin: parseBoolean(config.isAdmin),
    };
  },

  [types.SET_IMAGES_LIST_SUCCESS](state, images) {
    state.images = images.map(i => ({
      ...i,
      status: undefined,
      deleting: i.status === IMAGE_DELETE_SCHEDULED_STATUS,
      failedDelete: i.status === IMAGE_FAILED_DELETED_STATUS,
    }));
  },

  [types.UPDATE_IMAGE](state, image) {
    const index = state.images.findIndex(i => i.id === image.id);
    state.images.splice(index, 1, { ...image });
  },

  [types.SET_TAGS_LIST_SUCCESS](state, tags) {
    state.tags = tags;
  },

  [types.SET_MAIN_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },

  [types.SET_SHOW_GARBAGE_COLLECTION_TIP](state, showGarbageCollectionTip) {
    state.showGarbageCollectionTip = showGarbageCollectionTip;
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
