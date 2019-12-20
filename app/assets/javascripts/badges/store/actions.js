import axios from '~/lib/utils/axios_utils';
import types from './mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const transformBackendBadge = badge => ({
  ...convertObjectPropsToCamelCase(badge, true),
  isDeleting: false,
});

export default {
  requestNewBadge({ commit }) {
    commit(types.REQUEST_NEW_BADGE);
  },
  receiveNewBadge({ commit }, newBadge) {
    commit(types.RECEIVE_NEW_BADGE, newBadge);
  },
  receiveNewBadgeError({ commit }) {
    commit(types.RECEIVE_NEW_BADGE_ERROR);
  },
  addBadge({ dispatch, state }) {
    const newBadge = state.badgeInAddForm;
    const endpoint = state.apiEndpointUrl;
    dispatch('requestNewBadge');
    return axios
      .post(endpoint, {
        name: newBadge.name,
        image_url: newBadge.imageUrl,
        link_url: newBadge.linkUrl,
      })
      .catch(error => {
        dispatch('receiveNewBadgeError');
        throw error;
      })
      .then(res => {
        dispatch('receiveNewBadge', transformBackendBadge(res.data));
      });
  },
  requestDeleteBadge({ commit }, badgeId) {
    commit(types.REQUEST_DELETE_BADGE, badgeId);
  },
  receiveDeleteBadge({ commit }, badgeId) {
    commit(types.RECEIVE_DELETE_BADGE, badgeId);
  },
  receiveDeleteBadgeError({ commit }, badgeId) {
    commit(types.RECEIVE_DELETE_BADGE_ERROR, badgeId);
  },
  deleteBadge({ dispatch, state }, badge) {
    const badgeId = badge.id;
    dispatch('requestDeleteBadge', badgeId);
    const endpoint = `${state.apiEndpointUrl}/${badgeId}`;
    return axios
      .delete(endpoint)
      .catch(error => {
        dispatch('receiveDeleteBadgeError', badgeId);
        throw error;
      })
      .then(() => {
        dispatch('receiveDeleteBadge', badgeId);
      });
  },

  editBadge({ commit }, badge) {
    commit(types.START_EDITING, badge);
  },

  requestLoadBadges({ commit }, data) {
    commit(types.REQUEST_LOAD_BADGES, data);
  },
  receiveLoadBadges({ commit }, badges) {
    commit(types.RECEIVE_LOAD_BADGES, badges);
  },
  receiveLoadBadgesError({ commit }) {
    commit(types.RECEIVE_LOAD_BADGES_ERROR);
  },

  loadBadges({ dispatch, state }, data) {
    dispatch('requestLoadBadges', data);
    const endpoint = state.apiEndpointUrl;
    return axios
      .get(endpoint)
      .catch(error => {
        dispatch('receiveLoadBadgesError');
        throw error;
      })
      .then(res => {
        dispatch('receiveLoadBadges', res.data.map(transformBackendBadge));
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
    if (!linkUrl || linkUrl.trim() === '' || !imageUrl || imageUrl.trim() === '') {
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
      .catch(error => {
        dispatch('receiveRenderedBadgeError');
        throw error;
      })
      .then(res => {
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
      .catch(error => {
        dispatch('receiveUpdatedBadgeError');
        throw error;
      })
      .then(res => {
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
