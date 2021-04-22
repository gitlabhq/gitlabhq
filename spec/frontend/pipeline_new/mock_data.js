export const mockRefs = {
  Branches: ['main', 'branch-1', 'branch-2'],
  Tags: ['1.0.0', '1.1.0', '1.2.0'],
};

export const mockFilteredRefs = {
  Branches: ['branch-1'],
  Tags: ['1.0.0', '1.1.0'],
};

export const mockQueryParams = {
  refParam: 'tag-1',
  variableParams: {
    test_var: 'test_var_val',
  },
  fileParams: {
    test_file: 'test_file_val',
  },
};

export const mockProjectId = '21';

export const mockPostParams = {
  ref: 'tag-1',
  variables_attributes: [
    { key: 'test_var', secret_value: 'test_var_val', variable_type: 'env_var' },
    { key: 'test_file', secret_value: 'test_file_val', variable_type: 'file' },
  ],
};

export const mockError = {
  errors: [
    'test job: chosen stage does not exist; available stages are .pre, build, test, deploy, .post',
  ],
  warnings: [
    'jobs:build1 may allow multiple pipelines to run for a single action due to `rules:when` clause with no `workflow:rules` - read more: https://docs.gitlab.com/ee/ci/troubleshooting.html#pipeline-warnings',
    'jobs:build2 may allow multiple pipelines to run for a single action due to `rules:when` clause with no `workflow:rules` - read more: https://docs.gitlab.com/ee/ci/troubleshooting.html#pipeline-warnings',
    'jobs:build3 may allow multiple pipelines to run for a single action due to `rules:when` clause with no `workflow:rules` - read more: https://docs.gitlab.com/ee/ci/troubleshooting.html#pipeline-warnings',
  ],
  total_warnings: 7,
};

export const mockBranchRefs = ['main', 'dev', 'release'];

export const mockTagRefs = ['1.0.0', '1.1.0', '1.2.0'];
