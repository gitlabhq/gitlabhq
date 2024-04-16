import { groupMemberRequestFormatter } from '~/groups/members/utils';
import initInviteGroupTrigger from '~/invite_members/init_invite_group_trigger';
import initInviteGroupsModal from '~/invite_members/init_invite_groups_modal';
import { s__ } from '~/locale';
import { initMembersApp } from '~/members';
import { EE_GROUPS_APP_OPTIONS, MEMBER_TYPES } from 'ee_else_ce/members/constants';
import { groupLinkRequestFormatter } from '~/members/utils';

const SHARED_FIELDS = ['account', 'maxRole', 'expiration', 'actions'];
const APP_OPTIONS = {
  [MEMBER_TYPES.user]: {
    tableFields: SHARED_FIELDS.concat(['source', 'activity']),
    tableSortableFields: [
      'account',
      'granted',
      'maxRole',
      'lastSignIn',
      'userCreatedAt',
      'lastActivityOn',
    ],
    requestFormatter: groupMemberRequestFormatter,
    filteredSearchBar: {
      show: true,
      tokens: ['two_factor', 'with_inherited_permissions', 'enterprise', 'user_type'],
      searchParam: 'search',
      placeholder: s__('Members|Filter members'),
      recentSearchesStorageKey: 'group_members',
    },
  },
  [MEMBER_TYPES.group]: {
    tableFields: SHARED_FIELDS.concat(['source', 'granted']),
    requestFormatter: groupLinkRequestFormatter,
    filteredSearchBar: {
      show: true,
      tokens: ['groups_with_inherited_permissions'],
      searchParam: 'search_groups',
      placeholder: s__('Members|Filter groups'),
      recentSearchesStorageKey: 'group_links_members',
    },
  },
  [MEMBER_TYPES.invite]: {
    tableFields: SHARED_FIELDS.concat('invited'),
    requestFormatter: groupMemberRequestFormatter,
    filteredSearchBar: {
      show: true,
      tokens: [],
      searchParam: 'search_invited',
      placeholder: s__('Members|Search invited'),
      recentSearchesStorageKey: 'group_invited_members',
    },
  },
  [MEMBER_TYPES.accessRequest]: {
    tableFields: SHARED_FIELDS.concat('requested'),
    requestFormatter: groupMemberRequestFormatter,
  },
  ...EE_GROUPS_APP_OPTIONS,
};

initMembersApp(document.querySelector('.js-group-members-list-app'), APP_OPTIONS);

initInviteGroupsModal();
initInviteGroupTrigger();
