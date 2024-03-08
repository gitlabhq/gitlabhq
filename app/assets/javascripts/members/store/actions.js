import axios from '~/lib/utils/axios_utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import * as types from './mutation_types';

export const updateMemberRole = async (
  { state, commit },
  { memberId, accessLevel, memberRoleId },
) => {
  try {
    return await axios.put(
      state.memberPath.replace(/:id$/, memberId),
      state.requestFormatter({ accessLevel, memberRoleId }),
    );
  } catch (error) {
    commit(types.RECEIVE_MEMBER_ROLE_ERROR, { error });

    throw error;
  }
};

export const showRemoveGroupLinkModal = ({ commit }, groupLink) => {
  commit(types.SHOW_REMOVE_GROUP_LINK_MODAL, groupLink);
};

export const hideRemoveGroupLinkModal = ({ commit }) => {
  commit(types.HIDE_REMOVE_GROUP_LINK_MODAL);
};

export const showRemoveMemberModal = ({ commit }, modalData) => {
  commit(types.SHOW_REMOVE_MEMBER_MODAL, modalData);
};

export const hideRemoveMemberModal = ({ commit }) => {
  commit(types.HIDE_REMOVE_MEMBER_MODAL);
};

export const updateMemberExpiration = async ({ state, commit }, { memberId, expiresAt }) => {
  try {
    await axios.put(
      state.memberPath.replace(':id', memberId),
      state.requestFormatter({ expires_at: expiresAt ? formatDate(expiresAt, 'isoDate') : '' }),
    );

    commit(types.RECEIVE_MEMBER_EXPIRATION_SUCCESS, {
      memberId,
      expiresAt: expiresAt ? formatDate(expiresAt, 'isoUtcDateTime') : null,
    });
  } catch (error) {
    commit(types.RECEIVE_MEMBER_EXPIRATION_ERROR, { error });

    throw error;
  }
};
