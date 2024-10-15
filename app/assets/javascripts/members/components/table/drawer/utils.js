import axios from 'axios';
import { roleDropdownItems, initialSelectedRole } from '~/members/utils';
import {
  GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME,
  MEMBER_ACCESS_LEVEL_PROPERTY_NAME,
  MEMBERS_TAB_TYPES,
} from '~/members/constants';

// EE overrides these.
export const getRoleDropdownItems = roleDropdownItems;
export const getMemberRole = initialSelectedRole;

// The API to update members uses different property names for the access level, depending on if it's a user or a group.
// Users use 'access_level', groups use 'group_access'.
const ACCESS_LEVEL_PROPERTY_NAME = {
  [MEMBERS_TAB_TYPES.user]: MEMBER_ACCESS_LEVEL_PROPERTY_NAME,
  [MEMBERS_TAB_TYPES.group]: GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME,
};

export const callRoleUpdateApi = async (member, role) => {
  const accessLevelProp = ACCESS_LEVEL_PROPERTY_NAME[member.namespace];

  return axios.put(member.memberPath, {
    [accessLevelProp]: role.accessLevel,
    member_role_id: role.memberRoleId || null,
  });
};

export const setMemberRole = (member, role) => {
  // eslint-disable-next-line no-param-reassign
  member.accessLevel = {
    stringValue: role.text,
    integerValue: role.accessLevel,
    description: role.description,
    memberRoleId: role.memberRoleId,
  };
};
