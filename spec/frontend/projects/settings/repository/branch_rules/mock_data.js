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
            __typename: 'BranchRule',
          },
          {
            name: 'test-*',
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
  approvalDetails: ['requires approval from TEST', '2 status checks'],
};
