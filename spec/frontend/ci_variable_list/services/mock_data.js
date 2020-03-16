export default {
  mockVariables: [
    {
      environment_scope: 'All environments',
      id: 113,
      key: 'test_var',
      masked: false,
      protected: false,
      secret_value: 'test_val',
      value: 'test_val',
      variable_type: 'Var',
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
      environment_scope: 'All',
      id: 113,
      key: 'test_var',
      masked: false,
      protected: false,
      secret_value: 'test_val',
      value: 'test_val',
      variable_type: 'Var',
    },
    {
      environment_scope: 'All',
      id: 114,
      key: 'test_var_2',
      masked: false,
      protected: false,
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
};
