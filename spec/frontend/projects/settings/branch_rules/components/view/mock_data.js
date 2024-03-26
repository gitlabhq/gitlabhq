const usersMock = [
  {
    id: '123',
    username: 'usr1',
    webUrl: 'http://test.test/usr1',
    name: 'User 1',
    avatarUrl: 'http://test.test/avt1.png',
  },
  {
    id: '456',
    username: 'usr2',
    webUrl: 'http://test.test/usr2',
    name: 'User 2',
    avatarUrl: 'http://test.test/avt2.png',
  },
  {
    id: '789',
    username: 'usr3',
    webUrl: 'http://test.test/usr3',
    name: 'User 3',
    avatarUrl: 'http://test.test/avt3.png',
  },
  {
    id: '987',
    username: 'usr4',
    webUrl: 'http://test.test/usr4',
    name: 'User 4',
    avatarUrl: 'http://test.test/avt4.png',
  },
  {
    id: '654',
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

export const approvalRulesMock = [
  {
    __typename: 'ApprovalProjectRule',
    id: '123',
    name: 'test',
    type: 'REGULAR',
    eligibleApprovers: { nodes: usersMock },
    approvalsRequired,
  },
];

export const statusChecksRulesMock = [
  { __typename: 'StatusCheckRule', id: '123', name: 'test', externalUrl: 'https://test.test' },
  { __typename: 'StatusCheckRule', id: '456', name: 'test 2', externalUrl: 'https://test2.test2' },
];

export const protectionPropsMock = {
  header: 'Test protection',
  headerLinkTitle: 'Test link title',
  headerLinkHref: 'Test link href',
  roles: accessLevelsMock,
  users: usersMock,
  groups: groupsMock,
  approvals: approvalRulesMock,
  statusChecks: statusChecksRulesMock,
};

export const protectionRowPropsMock = {
  title: 'Test title',
  users: usersMock,
  accessLevels: accessLevelsMock,
  approvalsRequired,
  statusCheckUrl: statusChecksRulesMock[0].externalUrl,
};

export const accessLevelsMockResponse = [
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      accessLevel: 30,
      accessLevelDescription: 'Maintainers',
    },
  },
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      accessLevel: 40,
      accessLevelDescription: 'Maintainers + Developers',
    },
  },
];

export const matchingBranchesCount = 3;

export const branchProtectionsMockResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      __typename: 'Project',
      branchRules: {
        __typename: 'BranchRuleConnection',
        nodes: [
          {
            __typename: 'BranchRule',
            name: 'main',
            isDefault: true,
            id: 'gid://gitlab/Projects/BranchRule/1',
            matchingBranchesCount,
            branchProtection: {
              __typename: 'BranchProtection',
              allowForcePush: true,
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
            isDefault: false,
            id: 'gid://gitlab/Projects/BranchRule/2',
            matchingBranchesCount,
            branchProtection: {
              __typename: 'BranchProtection',
              allowForcePush: true,
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
        ],
      },
    },
  },
};

export const deleteBranchRuleMockResponse = {
  data: {
    branchRuleDelete: {
      errors: [],
      __typename: 'BranchRuleDeletePayload',
    },
  },
};

export const editBranchRuleMockResponse = {
  data: {
    branchRule: {
      errors: [],
      __typename: 'BranchRuleEditPayload',
    },
  },
};

export const protectableBranches = ['make-release-umd-bundle', 'main', 'v2.x'];

export const protectableBranchesMockResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      protectableBranches,
      __typename: 'Project',
    },
  },
};
