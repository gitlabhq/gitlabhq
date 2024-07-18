export const generateVariablePairs = (count) => {
  return Array.from({ length: count }).map((_, index) => ({
    key: `key_${index}`,
    value: `value_${index}`,
  }));
};

export const mockManualVariableConnection = (variables = []) => ({
  data: {
    project: {
      __typename: 'Project',
      id: 'root/ci-project/1',
      pipeline: {
        id: '1',
        manualVariables: {
          __typename: 'CiManualVariableConnection',
          nodes: variables.map((variable) => ({
            ...variable,
            id: variable.key,
          })),
        },
        __typename: 'Pipeline',
      },
    },
  },
});
