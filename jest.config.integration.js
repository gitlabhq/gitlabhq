const checkEnvironment = require('./config/helpers/check_frontend_integration_env');
const baseConfig = require('./jest.config.base');

checkEnvironment();

console.log(`
PSA: Running into unexpected and/or strange frontend integration test errors?
Please help improve our error logging by following the instructions on this issue:

    https://gitlab.com/gitlab-org/gitlab/-/issues/345513
`);

module.exports = {
  ...baseConfig('spec/frontend_integration', {
    moduleNameMapper: {
      '^test_helpers(/.*)$': '<rootDir>/spec/frontend_integration/test_helpers$1',
      '^ee_else_ce_test_helpers(/.*)$': '<rootDir>/spec/frontend_integration/test_helpers$1',
      '^jh_else_ce_test_helpers(/.*)$': '<rootDir>/spec/frontend_integration/test_helpers$1',
    },
    moduleNameMapperEE: {
      '^ee_else_ce_test_helpers(/.*)$': '<rootDir>/ee/spec/frontend_integration/test_helpers$1',
    },
    moduleNameMapperJH: {
      '^jh_else_ce_test_helpers(/.*)$': '<rootDir>/jh/spec/frontend_integration/test_helpers$1',
    },
    // We need to include spec/frontend in `roots` for the __mocks__ to be found
    roots: ['<rootDir>/spec/frontend_integration/', '<rootDir>/spec/frontend/'],
    rootsEE: ['<rootDir>/ee/spec/frontend_integration/'],
    rootsJH: ['<rootDir>/jh/spec/frontend_integration/'],
  }),
  fakeTimers: {
    enableGlobally: false,
  },
  testTimeout: process.env.CI ? 20000 : 7000,
};
