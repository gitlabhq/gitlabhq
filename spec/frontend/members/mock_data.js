export const member = {
  requestedAt: null,
  canUpdate: false,
  canRemove: false,
  canOverride: false,
  isOverridden: false,
  accessLevel: { integerValue: 50, stringValue: 'Owner' },
  source: {
    id: 178,
    name: 'Foo Bar',
    webUrl: 'https://gitlab.com/groups/foo-bar',
  },
  user: {
    id: 123,
    name: 'Administrator',
    username: 'root',
    webUrl: 'https://gitlab.com/root',
    avatarUrl: 'https://www.gravatar.com/avatar/4816142ef496f956a277bedf1a40607b?s=80&d=identicon',
    blocked: false,
    twoFactorEnabled: false,
  },
  id: 238,
  createdAt: '2020-07-17T16:22:46.923Z',
  expiresAt: null,
  usingLicense: false,
  groupSso: false,
  groupManagedAccount: false,
  validRoles: {
    Guest: 10,
    Reporter: 20,
    Developer: 30,
    Maintainer: 40,
    Owner: 50,
    'Minimal Access': 5,
  },
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
  createdAt: '2020-08-06T15:31:07.662Z',
  expiresAt: null,
  validRoles: { Guest: 10, Reporter: 20, Developer: 30, Maintainer: 40, Owner: 50 },
};

const { user, ...memberNoUser } = member;
export const invite = {
  ...memberNoUser,
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
