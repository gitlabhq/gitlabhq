export const branchRulesMockResponse = {
  data: {
    project: {
      __typename: 'Project',
      branchRules: {
        __typename: 'BranchRuleConnection',
        nodes: [
          {
            name: 'master',
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
