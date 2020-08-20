export const mockRefs = ['master', 'branch-1', 'tag-1'];

export const mockParams = {
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
  variables: [
    { key: 'test_var', value: 'test_var_val', variable_type: 'env_var' },
    { key: 'test_file', value: 'test_file_val', variable_type: 'file' },
  ],
};
