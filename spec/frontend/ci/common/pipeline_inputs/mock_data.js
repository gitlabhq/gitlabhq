/** mock data to be replaced with fixtures - https://gitlab.com/gitlab-org/gitlab/-/issues/525243 */

export const mockPipelineInputsResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/17',
      ciPipelineCreationInputs: [
        {
          name: 'deploy_environment',
          description: 'Specify deployment environment',
          default: 'staging',
          type: 'text',
          required: false,
          options: ['staging', 'production'],
          regex: '^(staging|production)$',
          rules: null,
        },
        {
          name: 'api_token',
          description: 'API token for deployment',
          default: '',
          type: 'text',
          required: true,
          options: [],
          regex: null,
          rules: null,
        },
        {
          name: 'tags',
          description: 'Tags for deployment',
          default: '',
          type: 'ARRAY',
          required: false,
          options: [],
          regex: null,
          rules: null,
        },
      ],
      __typename: 'Project',
    },
  },
};

export const mockPipelineInputsWithRules = {
  data: {
    project: {
      id: 'gid://gitlab/Project/17',
      ciPipelineCreationInputs: [
        {
          name: 'cloud_provider',
          description: 'Cloud provider selection',
          type: 'STRING',
          options: ['aws', 'gcp', 'azure'],
          default: 'aws',
          required: false,
          regex: null,
          rules: null,
        },
        {
          name: 'environment',
          description: 'Environment selection',
          type: 'STRING',
          options: ['dev', 'prod'],
          default: 'dev',
          required: false,
          regex: null,
          rules: null,
        },
        {
          name: 'instance_type',
          description: 'Instance type selection',
          type: 'STRING',
          options: [],
          default: '',
          required: false,
          regex: null,
          rules: [
            {
              conditionTree: {
                operator: 'AND',
                field: null,
                value: null,
                children: [
                  { field: 'cloud_provider', operator: 'equals', value: 'aws', children: null },
                  { field: 'environment', operator: 'equals', value: 'dev', children: null },
                ],
              },
              options: ['t3.micro', 't3.small'],
              default: 't3.micro',
            },
            {
              conditionTree: {
                operator: 'AND',
                field: null,
                value: null,
                children: [
                  { field: 'cloud_provider', operator: 'equals', value: 'aws', children: null },
                  { field: 'environment', operator: 'equals', value: 'prod', children: null },
                ],
              },
              options: ['m5.large', 'm5.xlarge'],
              default: 'm5.large',
            },
            {
              conditionTree: {
                field: 'cloud_provider',
                operator: 'equals',
                value: 'gcp',
                children: null,
              },
              options: ['e2-small', 'e2-medium'],
              default: 'e2-small',
            },
          ],
        },
      ],
      __typename: 'Project',
    },
  },
};

export const mockPipelineInputsWithComplexRules = {
  data: {
    project: {
      ...mockPipelineInputsWithRules.data.project,
      ciPipelineCreationInputs: [
        ...mockPipelineInputsWithRules.data.project.ciPipelineCreationInputs.slice(0, 2),
        {
          name: 'special_feature',
          description: 'Special feature that depends on complex conditions',
          type: 'STRING',
          options: [],
          default: '',
          required: false,
          regex: null,
          rules: [
            {
              conditionTree: {
                operator: 'OR',
                field: null,
                value: null,
                children: [
                  {
                    operator: 'AND',
                    field: null,
                    value: null,
                    children: [
                      { field: 'cloud_provider', operator: 'equals', value: 'aws' },
                      { field: 'environment', operator: 'equals', value: 'prod' },
                    ],
                  },
                  { field: 'cloud_provider', operator: 'equals', value: 'azure', children: null },
                ],
              },
              options: ['premium-feature', 'enterprise-feature'],
              default: 'premium-feature',
            },
          ],
        },
      ],
    },
  },
};

export const mockEmptyInputsResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/17',
      ciPipelineCreationInputs: [],
      __typename: 'Project',
    },
  },
};

export const mockPipelineInputsErrorResponse = {
  errors: [
    {
      message: 'ref can only be an existing branch or tag',
      path: ['project', 'ciPipelineCreationInputs'],
    },
  ],
  data: {},
};
