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
            branchProtection: {
              allowForcePush: true,
              codeOwnerApprovalRequired: true,
            },
            approvalRules: {
              nodes: [{ id: 1 }],
              __typename: 'ApprovalProjectRuleConnection',
            },
            externalStatusChecks: {
              nodes: [{ id: 1 }, { id: 2 }],
              __typename: 'BranchRule',
            },
            __typename: 'BranchRule',
          },
          {
            name: 'test-*',
            isDefault: false,
            branchProtection: {
              allowForcePush: false,
              codeOwnerApprovalRequired: false,
            },
            approvalRules: {
              nodes: [],
              __typename: 'ApprovalProjectRuleConnection',
            },
            externalStatusChecks: {
              nodes: [],
              __typename: 'BranchRule',
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
  branchProtection: {
    allowForcePush: true,
    codeOwnerApprovalRequired: true,
  },
  approvalRulesTotal: 1,
  statusChecksTotal: 2,
};

export const branchRuleWithoutDetailsPropsMock = {
  name: 'main',
  isDefault: false,
  branchProtection: {
    allowForcePush: false,
    codeOwnerApprovalRequired: false,
  },
  approvalRulesTotal: 0,
  statusChecksTotal: 0,
};
