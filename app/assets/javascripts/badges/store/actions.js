import axios from '~/lib/utils/axios_utils';
import {
  convertObjectPropsToCamelCase,
  normalizeHeaders,
  parseIntPagination,
} from '~/lib/utils/common_utils';
import { isValidURL } from '~/lib/utils/url_utility';
import { PAGE_SIZE } from '../constants';
import types from './mutation_types';

export const transformBackendBadge = (badge) => ({
  ...convertObjectPropsToCamelCase(badge, true),
  isDeleting: false,
});

export default {
  addBadge({ dispatch, commit, state }) {
    const newBadge = state.badgeInAddForm;
    const endpoint = state.apiEndpointUrl;
    commit(types.REQUEST_NEW_BADGE);
    return axios
      .post(endpoint, {
        name: newBadge.name,
        image_url: newBadge.imageUrl,
        link_url: newBadge.linkUrl,
      })
      .catch((error) => {
        commit(types.RECEIVE_NEW_BADGE_ERROR);
        throw error;
      })
      .then(() => {
        commit(types.RECEIVE_NEW_BADGE);
        dispatch('loadBadges', { page: state.pagination.page });
      });
  },

  deleteBadge({ dispatch, commit, state }, badge) {
    const badgeId = badge.id;
    commit(types.REQUEST_DELETE_BADGE, badgeId);
    const endpoint = `${state.apiEndpointUrl}/${badgeId}`;
    return axios
      .delete(endpoint)
      .catch((error) => {
        commit(types.RECEIVE_DELETE_BADGE_ERROR, badgeId);
        throw error;
      })
      .then(() => {
        dispatch('loadBadges', { page: state.pagination.page });
      });
  },

  editBadge({ commit }, badge) {
    commit(types.START_EDITING, badge);
  },

  loadBadges({ commit, state }, { page }) {
    commit(types.REQUEST_LOAD_BADGES);
    const endpoint = state.apiEndpointUrl;
    return axios
      .get(endpoint, {
        params: {
          page,
          per_page: PAGE_SIZE,
        },
      })
      .catch((error) => {
        commit(types.RECEIVE_LOAD_BADGES_ERROR);
        throw error;
      })
      .then(({ data, headers }) => {
        commit(types.RECEIVE_LOAD_BADGES, data.map(transformBackendBadge));
        commit(types.RECEIVE_PAGINATION, parseIntPagination(normalizeHeaders(headers)));
      });
  },

  requestRenderedBadge({ commit }) {
    commit(types.REQUEST_RENDERED_BADGE);
  },
  receiveRenderedBadge({ commit }, renderedBadge) {
    commit(types.RECEIVE_RENDERED_BADGE, renderedBadge);
  },
  receiveRenderedBadgeError({ commit }) {
    commit(types.RECEIVE_RENDERED_BADGE_ERROR);
  },

  renderBadge({ dispatch, state }) {
    const badge = state.isEditing ? state.badgeInEditForm : state.badgeInAddForm;
    const { linkUrl, imageUrl } = badge;
    if (
      !linkUrl ||
      linkUrl.trim() === '' ||
      !isValidURL(linkUrl) ||
      !imageUrl ||
      imageUrl.trim() === '' ||
      !isValidURL(imageUrl)
    ) {
      return Promise.resolve(badge);
    }

    dispatch('requestRenderedBadge');

    const parameters = [
      `link_url=${encodeURIComponent(linkUrl)}`,
      `image_url=${encodeURIComponent(imageUrl)}`,
    ].join('&');
    const renderEndpoint = `${state.apiEndpointUrl}/render?${parameters}`;
    return axios
      .get(renderEndpoint)
      .catch((error) => {
        dispatch('receiveRenderedBadgeError');
        throw error;
      })
      .then((res) => {
        dispatch('receiveRenderedBadge', transformBackendBadge(res.data));
      });
  },

  requestUpdatedBadge({ commit }) {
    commit(types.REQUEST_UPDATED_BADGE);
  },
  receiveUpdatedBadge({ commit }, updatedBadge) {
    commit(types.RECEIVE_UPDATED_BADGE, updatedBadge);
  },
  receiveUpdatedBadgeError({ commit }) {
    commit(types.RECEIVE_UPDATED_BADGE_ERROR);
  },

  saveBadge({ dispatch, state }) {
    const badge = state.badgeInEditForm;
    const endpoint = `${state.apiEndpointUrl}/${badge.id}`;
    dispatch('requestUpdatedBadge');
    return axios
      .put(endpoint, {
        name: badge.name,
        image_url: badge.imageUrl,
        link_url: badge.linkUrl,
      })
      .catch((error) => {
        dispatch('receiveUpdatedBadgeError');
        throw error;
      })
      .then((res) => {
        dispatch('receiveUpdatedBadge', transformBackendBadge(res.data));
      });
  },

  stopEditing({ commit }) {
    commit(types.STOP_EDITING);
  },

  updateBadgeInForm({ commit }, badge) {
    commit(types.UPDATE_BADGE_IN_FORM, badge);
  },

  updateBadgeInModal({ commit }, badge) {
    commit(types.UPDATE_BADGE_IN_MODAL, badge);
  },
};
