export const accessLevelsMockResponse = [
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      accessLevel: 40,
      accessLevelDescription: 'Developers',
    },
  },
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      accessLevel: 40,
      accessLevelDescription: 'Maintainers',
    },
  },
];

export const branchRulesMockResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      __typename: 'Project',
      branchRules: {
        __typename: 'BranchRuleConnection',
        nodes: [
          {
            name: 'main',
            id: 'gid://gitlab/Projects/BranchRule/1',
            isDefault: true,
            matchingBranchesCount: 1,
            branchProtection: {
              allowForcePush: true,
              mergeAccessLevels: {
                edges: [],
                __typename: 'MergeAccessLevelConnection',
              },
              pushAccessLevels: {
                edges: accessLevelsMockResponse,
                __typename: 'PushAccessLevelConnection',
              },
            },
            __typename: 'BranchRule',
          },
          {
            name: 'test-*',
            id: 'gid://gitlab/Projects/BranchRule/2',
            isDefault: false,
            matchingBranchesCount: 2,
            branchProtection: {
              allowForcePush: false,
              mergeAccessLevels: {
                edges: [],
                __typename: 'MergeAccessLevelConnection',
              },
              pushAccessLevels: {
                edges: [],
                __typename: 'PushAccessLevelConnection',
              },
            },
            __typename: 'BranchRule',
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

export const createBranchRuleMockResponse = {
  data: {
    branchRuleCreate: {
      errors: [],
      branchRule: {
        name: '*dkd',
        __typename: 'BranchRule',
      },
      __typename: 'BranchRuleCreatePayload',
    },
  },
};

export const appProvideMock = {
  projectPath: 'some/project/path',
  branchRulesPath: 'settings/repository/branch_rules',
};

export const branchRuleProvideMock = {
  branchRulesPath: 'settings/repository/branch_rules',
};

export const branchRulePropsMock = {
  name: 'branch-with-$speci@l-#-chars',
  isDefault: true,
  matchingBranchesCount: 1,
  branchProtection: {
    allowForcePush: true,
    codeOwnerApprovalRequired: false,
    pushAccessLevels: {
      edges: accessLevelsMockResponse,
    },
  },
  approvalRulesTotal: 0,
  statusChecksTotal: 0,
};

export const branchRuleWithoutDetailsPropsMock = {
  name: 'branch-1',
  isDefault: false,
  matchingBranchesCount: 1,
  branchProtection: null,
  approvalRulesTotal: 0,
  statusChecksTotal: 0,
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
