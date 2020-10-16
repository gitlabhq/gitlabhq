import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';

export const updateMemberRole = async ({ state, commit }, { memberId, accessLevel }) => {
  try {
    await axios.put(
      state.memberPath.replace(/:id$/, memberId),
      state.requestFormatter({ accessLevel: accessLevel.integerValue }),
    );

    commit(types.RECEIVE_MEMBER_ROLE_SUCCESS, { memberId, accessLevel });
  } catch (error) {
    commit(types.RECEIVE_MEMBER_ROLE_ERROR);

    throw error;
  }
};

export const showRemoveGroupLinkModal = ({ commit }, groupLink) => {
  commit(types.SHOW_REMOVE_GROUP_LINK_MODAL, groupLink);
};

export const hideRemoveGroupLinkModal = ({ commit }) => {
  commit(types.HIDE_REMOVE_GROUP_LINK_MODAL);
};
