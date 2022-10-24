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
            branchProtection: {
              allowForcePush: true,
              codeOwnerApprovalRequired: true,
            },
            __typename: 'BranchRule',
          },
          {
            name: 'test-*',
            branchProtection: {
              allowForcePush: false,
              codeOwnerApprovalRequired: false,
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
  isProtected: true,
  branchProtection: {
    allowForcePush: true,
    codeOwnerApprovalRequired: true,
  },
};

export const branchRuleWithoutDetailsPropsMock = {
  name: 'main',
  isDefault: false,
  isProtected: false,
  branchProtection: {
    allowForcePush: false,
    codeOwnerApprovalRequired: false,
  },
};
