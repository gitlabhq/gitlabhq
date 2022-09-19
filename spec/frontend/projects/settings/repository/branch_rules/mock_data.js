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

export const propsDataMock = {
  projectPath: 'some/project/path',
};
