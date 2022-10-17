const usersMock = [
  {
    username: 'usr1',
    webUrl: 'http://test.test/usr1',
    name: 'User 1',
    avatarUrl: 'http://test.test/avt1.png',
  },
  {
    username: 'usr2',
    webUrl: 'http://test.test/usr2',
    name: 'User 2',
    avatarUrl: 'http://test.test/avt2.png',
  },
  {
    username: 'usr3',
    webUrl: 'http://test.test/usr3',
    name: 'User 3',
    avatarUrl: 'http://test.test/avt3.png',
  },
  {
    username: 'usr4',
    webUrl: 'http://test.test/usr4',
    name: 'User 4',
    avatarUrl: 'http://test.test/avt4.png',
  },
  {
    username: 'usr5',
    webUrl: 'http://test.test/usr5',
    name: 'User 5',
    avatarUrl: 'http://test.test/avt5.png',
  },
];

const accessLevelsMock = [
  { accessLevelDescription: 'Administrator' },
  { accessLevelDescription: 'Maintainer' },
];

const approvalsRequired = 3;

const groupsMock = [{ name: 'test_group_1' }, { name: 'test_group_2' }];

export const protectionPropsMock = {
  header: 'Test protection',
  headerLinkTitle: 'Test link title',
  headerLinkHref: 'Test link href',
  roles: accessLevelsMock,
  users: usersMock,
  groups: groupsMock,
  approvals: [
    {
      name: 'test',
      eligibleApprovers: { nodes: usersMock },
      approvalsRequired,
    },
  ],
};

export const protectionRowPropsMock = {
  title: 'Test title',
  users: usersMock,
  accessLevels: accessLevelsMock,
  approvalsRequired,
};

export const accessLevelsMockResponse = [
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      accessLevel: 40,
      accessLevelDescription: 'Jona Langworth',
      group: null,
      user: {
        __typename: 'UserCore',
        id: '123',
        webUrl: 'test.com',
        name: 'peter',
        avatarUrl: 'test.com/user.png',
      },
    },
  },
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      accessLevel: 40,
      accessLevelDescription: 'Maintainers',
      group: null,
      user: null,
    },
  },
];

export const branchProtectionsMockResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/6',
      __typename: 'Project',
      branchRules: {
        __typename: 'BranchRuleConnection',
        nodes: [
          {
            __typename: 'BranchRule',
            name: 'main',
            branchProtection: {
              __typename: 'BranchProtection',
              allowForcePush: true,
              codeOwnerApprovalRequired: true,
              mergeAccessLevels: {
                __typename: 'MergeAccessLevelConnection',
                edges: accessLevelsMockResponse,
              },
              pushAccessLevels: {
                __typename: 'PushAccessLevelConnection',
                edges: accessLevelsMockResponse,
              },
            },
          },
          {
            __typename: 'BranchRule',
            name: '*',
            branchProtection: {
              __typename: 'BranchProtection',
              allowForcePush: true,
              codeOwnerApprovalRequired: true,
              mergeAccessLevels: {
                __typename: 'MergeAccessLevelConnection',
                edges: [],
              },
              pushAccessLevels: {
                __typename: 'PushAccessLevelConnection',
                edges: [],
              },
            },
          },
        ],
      },
    },
  },
};
