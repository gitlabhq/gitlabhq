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
        },
        {
          name: 'api_token',
          description: 'API token for deployment',
          default: '',
          type: 'text',
          required: true,
          options: [],
          regex: null,
        },
        {
          name: 'tags',
          description: 'Tags for deployment',
          default: '',
          type: 'ARRAY',
          required: false,
          options: [],
          regex: null,
        },
      ],
      __typename: 'Project',
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
};
