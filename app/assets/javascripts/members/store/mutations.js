import Vue from 'vue';
import { s__ } from '~/locale';
import * as types from './mutation_types';
import { findMember } from './utils';

export default {
  [types.RECEIVE_MEMBER_ROLE_SUCCESS](state, { memberId, accessLevel }) {
    const member = findMember(state, memberId);

    if (!member) {
      return;
    }

    Vue.set(member, 'accessLevel', accessLevel);
  },
  [types.RECEIVE_MEMBER_ROLE_ERROR](state, { error }) {
    state.errorMessage =
      error.response?.data?.message ||
      s__("Members|An error occurred while updating the member's role, please try again.");
    state.showError = true;
  },
  [types.RECEIVE_MEMBER_EXPIRATION_SUCCESS](state, { memberId, expiresAt }) {
    const member = findMember(state, memberId);

    if (!member) {
      return;
    }

    Vue.set(member, 'expiresAt', expiresAt);
  },
  [types.RECEIVE_MEMBER_EXPIRATION_ERROR](state, { error }) {
    state.errorMessage =
      error.response?.data?.message ||
      s__(
        "Members|An error occurred while updating the member's expiration date, please try again.",
      );
    state.showError = true;
  },
  [types.HIDE_ERROR](state) {
    state.showError = false;
    state.errorMessage = '';
  },
  [types.SHOW_REMOVE_GROUP_LINK_MODAL](state, groupLink) {
    state.removeGroupLinkModalVisible = true;
    state.groupLinkToRemove = groupLink;
  },
  [types.HIDE_REMOVE_GROUP_LINK_MODAL](state) {
    state.removeGroupLinkModalVisible = false;
  },
  [types.SHOW_REMOVE_MEMBER_MODAL](state, modalData) {
    state.removeMemberModalData = modalData;
    state.removeMemberModalVisible = true;
  },
  [types.HIDE_REMOVE_MEMBER_MODAL](state) {
    state.removeMemberModalVisible = false;
  },
};
