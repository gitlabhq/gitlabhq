import { EE_PROJECTS_APP_OPTIONS, MEMBER_TYPES } from 'ee_else_ce/members/constants';
import initImportProjectMembersTrigger from '~/invite_members/init_import_project_members_trigger';
import initImportProjectMembersModal from '~/invite_members/init_import_project_members_modal';
import initInviteGroupTrigger from '~/invite_members/init_invite_group_trigger';
import initInviteGroupsModal from '~/invite_members/init_invite_groups_modal';
import { s__ } from '~/locale';
import { initMembersApp } from '~/members';
import { groupLinkRequestFormatter } from '~/members/utils';
import { projectMemberRequestFormatter } from '~/projects/members/utils';

initImportProjectMembersModal();
initInviteGroupsModal();
initInviteGroupTrigger();
initImportProjectMembersTrigger();

const SHARED_FIELDS = ['account', 'maxRole', 'expiration', 'actions'];
initMembersApp(document.querySelector('.js-project-members-list-app'), {
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
    requestFormatter: projectMemberRequestFormatter,
    filteredSearchBar: {
      show: true,
      tokens: ['with_inherited_permissions'],
      searchParam: 'search',
      placeholder: s__('Members|Filter members'),
      recentSearchesStorageKey: 'project_members',
    },
  },
  [MEMBER_TYPES.group]: {
    tableFields: SHARED_FIELDS.concat(['source', 'granted']),
    requestFormatter: groupLinkRequestFormatter,
    filteredSearchBar: {
      show: true,
      tokens: ['groups_with_inherited_permissions'],
      searchParam: 'search_groups',
      placeholder: s__('Members|Search groups'),
      recentSearchesStorageKey: 'project_group_links',
    },
  },
  [MEMBER_TYPES.invite]: {
    tableFields: SHARED_FIELDS.concat('invited'),
    requestFormatter: projectMemberRequestFormatter,
  },
  [MEMBER_TYPES.accessRequest]: {
    tableFields: SHARED_FIELDS.concat('requested'),
    requestFormatter: projectMemberRequestFormatter,
  },
  ...EE_PROJECTS_APP_OPTIONS,
});
