export const mockProjectId = '21';

export const mockIdentityVerificationRequiredError = {
  data: {
    pipelineCreate: {
      clientMutationId: 'test-mutation-id',
      errors: ['Identity verification is required in order to run CI jobs'],
      pipeline: null,
      __typename: 'PipelineCreatePayload',
    },
  },
};

export const mockBranchRefs = ['main', 'dev', 'release'];

export const mockTagRefs = ['1.0.0', '1.1.0', '1.2.0'];

export const mockVariables = [
  {
    uniqueId: 'var-refs/heads/main2',
    variableType: 'ENV_VAR',
    key: 'var_without_value',
    value: '',
  },
  {
    uniqueId: 'var-refs/heads/main3',
    variableType: 'ENV_VAR',
    key: 'var_with_value',
    value: 'test_value',
  },
  { uniqueId: 'var-refs/heads/main4', variableType: 'ENV_VAR', key: '', value: '' },
];

export const mockYamlVariables = [
  {
    description: 'This is a variable with a value.',
    key: 'VAR_WITH_VALUE',
    value: 'test_value',
    valueOptions: null,
  },
  {
    description: 'This is a variable with a multi-line value.',
    key: 'VAR_WITH_MULTILINE',
    value: `this is
      a multiline value`,
    valueOptions: null,
  },
  {
    description: 'This is a variable with predefined values.',
    key: 'VAR_WITH_OPTIONS',
    value: 'staging',
    valueOptions: ['development', 'staging', 'production'],
  },
];

const mockCiConfigVariablesQueryResponse = (ciConfigVariables) => ({
  data: {
    project: {
      id: 1,
      ciConfigVariables,
    },
  },
});

export const mockEmptyCiConfigVariablesResponse = mockCiConfigVariablesQueryResponse([]);

export const mockPipelineConfigButtonText = 'Go to the pipeline editor';
