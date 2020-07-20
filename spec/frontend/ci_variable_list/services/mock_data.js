export default {
  mockVariables: [
    {
      environment_scope: 'All (default)',
      id: 113,
      key: 'test_var',
      masked: false,
      protected: false,
      secret_value: 'test_val',
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
      secret_value: 'test_val',
      value: 'test_val',
      variable_type: 'env_var',
    },
    {
      environment_scope: '*',
      id: 114,
      key: 'test_var_2',
      masked: false,
      protected: false,
      secret_value: 'test_val_2',
      value: 'test_val_2',
      variable_type: 'file',
    },
  ],

  mockVariablesDisplay: [
    {
      environment_scope: 'All (default)',
      id: 113,
      key: 'test_var',
      masked: false,
      protected: false,
      protected_variable: false,
      secret_value: 'test_val',
      value: 'test_val',
      variable_type: 'Variable',
    },
    {
      environment_scope: 'All (default)',
      id: 114,
      key: 'test_var_2',
      masked: false,
      protected: false,
      protected_variable: false,
      secret_value: 'test_val_2',
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

  mockPemCert: `-----BEGIN CERTIFICATE REQUEST-----
  MIIB9TCCAWACAQAwgbgxGTAXBgNVBAoMEFF1b1ZhZGlzIExpbWl0ZWQxHDAaBgNV
  BAsME0RvY3VtZW50IERlcGFydG1lbnQxOTA3BgNVBAMMMFdoeSBhcmUgeW91IGRl
  Y29kaW5nIG1lPyAgVGhpcyBpcyBvbmx5IGEgdGVzdCEhITERMA8GA1UEBwwISGFt
  aWx0b24xETAPBgNVBAgMCFBlbWJyb2tlMQswCQYDVQQGEwJCTTEPMA0GCSqGSIb3
  DQEJARYAMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCJ9WRanG/fUvcfKiGl
  EL4aRLjGt537mZ28UU9/3eiJeJznNSOuNLnF+hmabAu7H0LT4K7EdqfF+XUZW/2j
  RKRYcvOUDGF9A7OjW7UfKk1In3+6QDCi7X34RE161jqoaJjrm/T18TOKcgkkhRzE
  apQnIDm0Ea/HVzX/PiSOGuertwIDAQABMAsGCSqGSIb3DQEBBQOBgQBzMJdAV4QP
  Awel8LzGx5uMOshezF/KfP67wJ93UW+N7zXY6AwPgoLj4Kjw+WtU684JL8Dtr9FX
  ozakE+8p06BpxegR4BR3FMHf6p+0jQxUEAkAyb/mVgm66TyghDGC6/YkiKoZptXQ
  98TwDIK/39WEB/V607As+KoYazQG8drorw==
  -----END CERTIFICATE REQUEST-----`,

  mockVariableScopes: [
    {
      id: 13,
      key: 'test_var_1',
      value: 'test_val_1',
      variable_type: 'File',
      protected: true,
      masked: true,
      environment_scope: 'All (default)',
      secret_value: 'test_val_1',
    },
    {
      id: 28,
      key: 'goku_var',
      value: 'goku_val',
      variable_type: 'Variable',
      protected: true,
      masked: true,
      environment_scope: 'staging',
      secret_value: 'goku_val',
    },
    {
      id: 25,
      key: 'test_var_4',
      value: 'test_val_4',
      variable_type: 'Variable',
      protected: false,
      masked: false,
      environment_scope: 'production',
      secret_value: 'test_val_4',
    },
    {
      id: 14,
      key: 'test_var_2',
      value: 'test_val_2',
      variable_type: 'File',
      protected: false,
      masked: false,
      environment_scope: 'staging',
      secret_value: 'test_val_2',
    },
    {
      id: 24,
      key: 'test_var_3',
      value: 'test_val_3',
      variable_type: 'Variable',
      protected: false,
      masked: false,
      environment_scope: 'All (default)',
      secret_value: 'test_val_3',
    },
    {
      id: 26,
      key: 'test_var_5',
      value: 'test_val_5',
      variable_type: 'Variable',
      protected: false,
      masked: false,
      environment_scope: 'production',
      secret_value: 'test_val_5',
    },
  ],
};
