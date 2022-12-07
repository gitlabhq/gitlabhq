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

export const matchingBranchesCount = 3;

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
            approvalRules: {
              __typename: 'ApprovalProjectRuleConnection',
              nodes: approvalRulesMock,
            },
            externalStatusChecks: {
              __typename: 'ExternalStatusCheckConnection',
              nodes: statusChecksRulesMock,
            },
            matchingBranchesCount,
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
            approvalRules: {
              __typename: 'ApprovalProjectRuleConnection',
              nodes: [],
            },
            externalStatusChecks: {
              __typename: 'ExternalStatusCheckConnection',
              nodes: [],
            },
            matchingBranchesCount,
          },
        ],
      },
    },
  },
};
