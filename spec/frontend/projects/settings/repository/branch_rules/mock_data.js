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
      id: '123',
      __typename: 'Project',
      branchRules: {
        __typename: 'BranchRuleConnection',
        nodes: [
          {
            name: 'main',
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

export const appProvideMock = {
  projectPath: 'some/project/path',
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
