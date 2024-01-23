import {
  MEMBER_TYPES,
  MEMBER_STATE_CREATED,
  MEMBER_MODEL_TYPE_GROUP_MEMBER,
} from '~/members/constants';

export const member = {
  requestedAt: null,
  canUpdate: false,
  canRemove: false,
  canOverride: false,
  isOverridden: false,
  isDirectMember: false,
  accessLevel: { integerValue: 50, stringValue: 'Owner' },
  source: {
    id: 178,
    fullName: 'Foo Bar',
    webUrl: 'https://gitlab.com/groups/foo-bar',
  },
  type: MEMBER_MODEL_TYPE_GROUP_MEMBER,
  state: MEMBER_STATE_CREATED,
  user: {
    id: 123,
    createdAt: '2022-03-10T18:03:04.812Z',
    name: 'Administrator',
    username: 'root',
    webUrl: 'https://gitlab.com/root',
    avatarUrl: 'https://www.gravatar.com/avatar/4816142ef496f956a277bedf1a40607b?s=80&d=identicon',
    blocked: false,
    isBot: false,
    twoFactorEnabled: false,
    oncallSchedules: [{ name: 'schedule 1' }],
    escalationPolicies: [{ name: 'policy 1' }],
    availability: null,
    lastActivityOn: '2022-03-15',
    showStatus: true,
    email: 'my@email.com',
  },
  id: 238,
  createdAt: '2020-07-17T16:22:46.923Z',
  expiresAt: null,
  usingLicense: false,
  groupSso: false,
  groupManagedAccount: false,
  enterpriseUserOfThisGroup: false,
  validRoles: {
    Guest: 10,
    Reporter: 20,
    Developer: 30,
    Maintainer: 40,
    Owner: 50,
    'Minimal access': 5,
  },
  customRoles: [],
  customPermissions: [],
};

export const group = {
  accessLevel: { integerValue: 10, stringValue: 'Guest' },
  sharedWithGroup: {
    id: 24,
    name: 'Commit451',
    avatarUrl: '/uploads/-/system/user/avatar/1/avatar.png?width=40',
    fullPath: 'parent-group/commit451',
    fullName: 'Parent group / Commit451',
    webUrl: 'https://gitlab.com/groups/parent-group/commit451',
  },
  id: 3,
  isDirectMember: true,
  createdAt: '2020-08-06T15:31:07.662Z',
  expiresAt: null,
  validRoles: { Guest: 10, Reporter: 20, Developer: 30, Maintainer: 40, Owner: 50 },
};

export const privateGroup = {
  accessLevel: { integerValue: 10, stringValue: 'Guest' },
  isSharedWithGroupPrivate: true,
  sharedWithGroup: {
    id: 24,
  },
  id: 3,
  isDirectMember: true,
  createdAt: '2020-08-06T15:31:07.662Z',
  expiresAt: null,
  validRoles: { Guest: 10, Reporter: 20, Developer: 30, Maintainer: 40, Owner: 50 },
};

export const modalData = {
  isAccessRequest: true,
  isInvite: true,
  memberPath: '/groups/foo-bar/-/group_members/1',
  memberModelType: MEMBER_MODEL_TYPE_GROUP_MEMBER,
  message: 'Are you sure you want to remove John Smith?',
  userDeletionObstacles: { name: 'user', obstacles: [] },
};

const { user, ...memberNoUser } = member;
export const invite = {
  ...memberNoUser,
  state: MEMBER_STATE_CREATED,
  invite: {
    email: 'jewel@hudsonwalter.biz',
    avatarUrl: 'https://www.gravatar.com/avatar/cbab7510da7eec2f60f638261b05436d?s=80&d=identicon',
    canResend: true,
  },
};

export const orphanedMember = memberNoUser;

export const accessRequest = {
  ...member,
  requestedAt: '2020-07-17T16:22:46.923Z',
};

export const members = [member];

export const membersJsonString = JSON.stringify(members);

export const directMember = { ...member, isDirectMember: true };
export const inheritedMember = { ...member, isDirectMember: false };

export const member2faEnabled = { ...member, user: { ...member.user, twoFactorEnabled: true } };

export const paginationData = {
  current_page: 1,
  per_page: 5,
  total_items: 10,
  param_name: 'page',
  params: { search_groups: null },
};

export const pagination = {
  currentPage: 1,
  perPage: 5,
  totalItems: 10,
  paramName: 'page',
  params: { search_groups: null },
};

export const dataAttribute = JSON.stringify({
  [MEMBER_TYPES.user]: {
    members,
    pagination: paginationData,
    member_path: '/groups/foo-bar/-/group_members/:id',
    ldap_override_path: '/groups/ldap-group/-/group_members/:id/override',
    disable_two_factor_path: '/groups/ldap-group/-/two_factor_auth',
  },
  source_id: 234,
  can_manage_members: true,
});

export const permissions = {
  canRemove: true,
  canRemoveBlockedByLastOwner: false,
  canResend: true,
  canUpdate: true,
};
