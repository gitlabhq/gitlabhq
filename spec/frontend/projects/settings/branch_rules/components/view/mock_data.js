// Mocks for child components

export const usersMock = [
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

const groupsMock = [{ name: 'test_group_1' }, { name: 'test_group_2' }];

export const deployKeysMock = [
  {
    id: '123123',
    title: 'Deploy key 1',
    user: {
      name: 'User 1',
    },
  },
];

const accessLevelsMock = [30, 40];

const approvalsRequired = 3;

export const statusChecksRulesMock = [
  { __typename: 'StatusCheckRule', id: '123', name: 'test', externalUrl: 'https://test.test' },
  { __typename: 'StatusCheckRule', id: '456', name: 'test 2', externalUrl: 'https://test2.test2' },
];

export const protectionPropsMock = {
  header: 'Test protection',
  headerLinkTitle: 'Manage in protected branches',
  headerLinkHref: 'protected/branches',
  roles: accessLevelsMock,
  users: usersMock,
  groups: groupsMock,
  statusChecks: statusChecksRulesMock,
  emptyStateCopy: 'Test empty state',
};

export const protectionEmptyStatePropsMock = {
  header: '',
  headerLinkTitle: 'Status checks',
  emptyStateCopy: 'No status checks',
};

export const protectionRowPropsMock = {
  title: 'Test title',
  users: usersMock,
  groups: groupsMock,
  accessLevels: accessLevelsMock,
  approvalsRequired,
  statusCheckUrl: statusChecksRulesMock[0].externalUrl,
};

// Mocks for getBranchRulesDetails

const maintainersAccessLevel = {
  accessLevel: 40,
  accessLevelDescription: 'Maintainers',
};

const maintainersAndDevelopersAccessLevel = {
  accessLevel: 30,
  accessLevelDescription: 'Maintainers + Developers',
};

const pushAccessLevelEdges = [
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      ...maintainersAndDevelopersAccessLevel,
    },
  },
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      ...maintainersAccessLevel,
    },
  },
];

const mergeAccessLevelEdges = [
  {
    __typename: 'MergeAccessLevelEdge',
    node: {
      __typename: 'MergeAccessLevel',
      ...maintainersAndDevelopersAccessLevel,
    },
  },
  {
    __typename: 'MergeAccessLevelEdge',
    node: {
      __typename: 'MergeAccessLevel',
      ...maintainersAccessLevel,
    },
  },
];

export const matchingBranchesCount = 3;

export const branchProtectionsMockResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      __typename: 'Project',
      group: {
        id: 'gid://gitlab/Group/1',
        __typename: 'Group',
      },
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
                edges: mergeAccessLevelEdges,
              },
              pushAccessLevels: {
                __typename: 'PushAccessLevelConnection',
                edges: pushAccessLevelEdges,
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
                edges: mergeAccessLevelEdges,
              },
              pushAccessLevels: {
                __typename: 'PushAccessLevelConnection',
                edges: pushAccessLevelEdges,
              },
            },
          },
        ],
      },
    },
  },
};

export const branchProtectionsNoPushAccessMockResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      __typename: 'Project',
      branchRules: {
        __typename: 'BranchRuleConnection',
        nodes: [
          {
            __typename: 'BranchRule',
            name: '*-test',
            isDefault: false,
            id: 'gid://gitlab/Projects/BranchRule/2',
            matchingBranchesCount,
            branchProtection: {
              __typename: 'BranchProtection',
              allowForcePush: false,
              mergeAccessLevels: {
                __typename: 'MergeAccessLevelConnection',
                edges: mergeAccessLevelEdges,
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

export const predefinedBranchRulesMockResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      __typename: 'Project',
      group: {
        id: 'gid://gitlab/Group/1',
        __typename: 'Group',
      },
      branchRules: {
        __typename: 'BranchRuleConnection',
        nodes: [
          {
            name: 'All branches',
            id: 'gid://gitlab/Projects::AllBranchesRule/7',
            isDefault: false,
            matchingBranchesCount: 12,
            branchProtection: null,
            __typename: 'BranchRule',
          },
          {
            name: 'All protected branches',
            id: 'gid://gitlab/Projects::AllBranchesRule/6',
            isDefault: false,
            matchingBranchesCount: 14,
            branchProtection: null,
            __typename: 'BranchRule',
          },
        ],
      },
    },
  },
};

// Mocks for branchRuleDelete mutation

export const deleteBranchRuleMockResponse = {
  data: {
    branchRuleDelete: {
      errors: [],
      __typename: 'BranchRuleDeletePayload',
    },
  },
};

// Mocks for editBrachRule mutation

export const mergeAccessLevelsEditResponse = {
  __typename: 'MergeAccessLevelConnection',
  nodes: [
    {
      __typename: 'MergeAccessLevel',
      accessLevel: 30,
      accessLevelDescription: 'Maintainers',
    },
  ],
};

export const editBranchRuleMockResponse = {
  data: {
    branchRuleUpdate: {
      errors: [],
      __typename: 'BranchRuleEditPayload',
      branchRule: {
        __typename: 'BranchRule',
        name: 'newname',
        isDefault: true,
        id: 'gid://gitlab/Projects/BranchRule/1',
        matchingBranchesCount,
        branchProtection: {
          __typename: 'BranchProtection',
          allowForcePush: true,
          mergeAccessLevels: mergeAccessLevelsEditResponse,
          pushAccessLevels: {
            __typename: 'PushAccessLevelConnection',
            nodes: [],
          },
        },
      },
    },
  },
};

export const editRuleData = [{ accessLevel: 60 }, { accessLevel: 40 }, { accessLevel: 30 }];

export const editRuleDataNoAccessLevels = [];

export const editRuleDataNoOne = [{ accessLevel: 0 }];

// Mocks for getBranches query

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

// Mocks for drawer component

export const allowedToMergeDrawerProps = {
  isLoading: false,
  isOpen: false,
  title: 'Edit allowed to merge',
  roles: accessLevelsMock,
};
