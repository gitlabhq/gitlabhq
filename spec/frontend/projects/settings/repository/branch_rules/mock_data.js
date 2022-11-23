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
              codeOwnerApprovalRequired: true,
              mergeAccessLevels: {
                edges: [],
                __typename: 'MergeAccessLevelConnection',
              },
              pushAccessLevels: {
                edges: accessLevelsMockResponse,
                __typename: 'PushAccessLevelConnection',
              },
            },
            approvalRules: {
              nodes: [{ id: 1 }],
              __typename: 'ApprovalProjectRuleConnection',
            },
            externalStatusChecks: {
              nodes: [{ id: 1 }, { id: 2 }],
              __typename: 'ExternalStatusCheckConnection',
            },
            __typename: 'BranchRule',
          },
          {
            name: 'test-*',
            isDefault: false,
            matchingBranchesCount: 2,
            branchProtection: {
              allowForcePush: false,
              codeOwnerApprovalRequired: false,
              mergeAccessLevels: {
                edges: [],
                __typename: 'MergeAccessLevelConnection',
              },
              pushAccessLevels: {
                edges: [],
                __typename: 'PushAccessLevelConnection',
              },
            },
            approvalRules: {
              nodes: [],
              __typename: 'ApprovalProjectRuleConnection',
            },
            externalStatusChecks: {
              nodes: [],
              __typename: 'ExternalStatusCheckConnection',
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
  name: 'main',
  isDefault: true,
  matchingBranchesCount: 1,
  branchProtection: {
    allowForcePush: true,
    codeOwnerApprovalRequired: true,
    pushAccessLevels: {
      edges: accessLevelsMockResponse,
    },
  },
  approvalRulesTotal: 1,
  statusChecksTotal: 2,
};

export const branchRuleWithoutDetailsPropsMock = {
  name: 'branch-1',
  isDefault: false,
  matchingBranchesCount: 1,
  branchProtection: {
    allowForcePush: false,
    codeOwnerApprovalRequired: false,
  },
  approvalRulesTotal: 0,
  statusChecksTotal: 0,
};
