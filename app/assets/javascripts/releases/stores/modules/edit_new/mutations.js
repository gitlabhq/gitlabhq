import { uniqueId, cloneDeep } from 'lodash';
import { DEFAULT_ASSET_LINK_TYPE } from '../../../constants';
import * as types from './mutation_types';
import { SEARCH, CREATE, EXISTING_TAG, NEW_TAG } from './constants';

const findReleaseLink = (release, id) => {
  return release.assets.links.find((l) => l.id === id);
};

export default {
  [types.INITIALIZE_EMPTY_RELEASE](state) {
    state.release = {
      tagName: state.tagName,
      tagMessage: '',
      name: '',
      description: '',
      milestones: [],
      groupMilestones: [],
      releasedAt: state.originalReleasedAt,
      assets: {
        links: [],
      },
    };
  },
  [types.INITIALIZE_RELEASE](state, release) {
    state.release = release;
  },

  [types.REQUEST_RELEASE](state) {
    state.isFetchingRelease = true;
  },
  [types.RECEIVE_RELEASE_SUCCESS](state, data) {
    state.fetchError = undefined;
    state.isFetchingRelease = false;
    state.release = data;
    state.originalRelease = Object.freeze(cloneDeep(state.release));
    state.originalReleasedAt = state.originalRelease.releasedAt;
  },
  [types.RECEIVE_RELEASE_ERROR](state, error) {
    state.fetchError = error;
    state.isFetchingRelease = false;
    state.release = undefined;
  },

  [types.UPDATE_RELEASE_TAG_NAME](state, tagName) {
    state.release.tagName = tagName;
    state.existingRelease = null;
  },
  [types.UPDATE_RELEASE_TAG_MESSAGE](state, tagMessage) {
    state.release.tagMessage = tagMessage;
  },
  [types.UPDATE_CREATE_FROM](state, createFrom) {
    state.createFrom = createFrom;
  },
  [types.UPDATE_SHOW_CREATE_FROM](state, showCreateFrom) {
    state.showCreateFrom = showCreateFrom;
  },
  [types.UPDATE_RELEASE_TITLE](state, title) {
    state.release.name = title;
  },
  [types.UPDATE_RELEASE_NOTES](state, notes) {
    state.release.description = notes;
  },

  [types.UPDATE_RELEASE_MILESTONES](state, milestones) {
    state.release.milestones = milestones;
  },

  [types.UPDATE_RELEASE_GROUP_MILESTONES](state, groupMilestones) {
    state.release.groupMilestones = groupMilestones;
  },

  [types.REQUEST_SAVE_RELEASE](state) {
    state.isUpdatingRelease = true;
  },
  [types.RECEIVE_SAVE_RELEASE_SUCCESS](state) {
    state.updateError = undefined;
    state.isUpdatingRelease = false;
  },
  [types.RECEIVE_SAVE_RELEASE_ERROR](state, error) {
    state.updateError = error;
    state.isUpdatingRelease = false;
  },

  [types.ADD_EMPTY_ASSET_LINK](state) {
    state.release.assets.links.push({
      id: uniqueId('new-link-'),
      url: '',
      name: '',
      linkType: DEFAULT_ASSET_LINK_TYPE,
    });
  },

  [types.UPDATE_ASSET_LINK_URL](state, { linkIdToUpdate, newUrl }) {
    const linkToUpdate = findReleaseLink(state.release, linkIdToUpdate);
    linkToUpdate.url = newUrl;
  },

  [types.UPDATE_ASSET_LINK_NAME](state, { linkIdToUpdate, newName }) {
    const linkToUpdate = findReleaseLink(state.release, linkIdToUpdate);
    linkToUpdate.name = newName;
  },

  [types.UPDATE_ASSET_LINK_TYPE](state, { linkIdToUpdate, newType }) {
    const linkToUpdate = findReleaseLink(state.release, linkIdToUpdate);
    linkToUpdate.linkType = newType;
  },

  [types.REMOVE_ASSET_LINK](state, linkIdToRemove) {
    state.release.assets.links = state.release.assets.links.filter((l) => l.id !== linkIdToRemove);
  },

  [types.REQUEST_TAG_NOTES](state) {
    state.isFetchingTagNotes = true;
  },
  [types.RECEIVE_TAG_NOTES_SUCCESS](state, data) {
    state.fetchError = undefined;
    state.isFetchingTagNotes = false;
    state.tagNotes = data.message;
    state.existingRelease = data.release;
  },
  [types.RECEIVE_TAG_NOTES_ERROR](state, error) {
    state.fetchError = error;
    state.isFetchingTagNotes = false;
    state.tagNotes = '';
    state.existingRelease = null;
  },
  [types.UPDATE_INCLUDE_TAG_NOTES](state, includeTagNotes) {
    state.includeTagNotes = includeTagNotes;
  },
  [types.UPDATE_RELEASED_AT](state, releasedAt) {
    state.release.releasedAt = releasedAt;
  },

  [types.SET_SEARCHING](state) {
    state.step = SEARCH;
  },
  [types.SET_CREATING](state) {
    state.step = CREATE;
  },
  [types.SET_EXISTING_TAG](state) {
    state.tagStep = EXISTING_TAG;
  },
  [types.SET_NEW_TAG](state) {
    state.tagStep = NEW_TAG;
  },
};
