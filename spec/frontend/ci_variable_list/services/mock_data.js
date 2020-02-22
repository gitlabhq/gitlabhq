export default {
  mockVariables: [
    {
      environment_scope: 'All environments',
      id: 113,
      key: 'test_var',
      masked: false,
      protected: false,
      value: 'test_val',
      variable_type: 'Variable',
    },
  ],

  mockVariablesApi: [
    {
      environment_scope: '*',
      id: 113,
      key: 'test_var',
      masked: false,
      protected: false,
      value: 'test_val',
      variable_type: 'env_var',
    },
    {
      environment_scope: '*',
      id: 114,
      key: 'test_var_2',
      masked: false,
      protected: false,
      value: 'test_val_2',
      variable_type: 'file',
    },
  ],

  mockVariablesDisplay: [
    {
      environment_scope: 'All environments',
      id: 113,
      key: 'test_var',
      masked: false,
      protected: false,
      value: 'test_val',
      variable_type: 'Variable',
    },
    {
      environment_scope: 'All environments',
      id: 114,
      key: 'test_var_2',
      masked: false,
      protected: false,
      value: 'test_val_2',
      variable_type: 'File',
    },
  ],

  mockEnvironments: [
    {
      id: 28,
      name: 'staging',
      slug: 'staging',
      external_url: 'https://staging.example.com',
      state: 'available',
    },
    {
      id: 29,
      name: 'production',
      slug: 'production',
      external_url: 'https://production.example.com',
      state: 'available',
    },
  ],
};
