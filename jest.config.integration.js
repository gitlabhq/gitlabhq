const baseConfig = require('./jest.config.base');

module.exports = {
  ...baseConfig('spec/frontend_integration', {
    moduleNameMapper: {
      '^test_helpers(/.*)$': '<rootDir>/spec/frontend_integration/test_helpers$1',
      '^ee_else_ce_test_helpers(/.*)$': '<rootDir>/spec/frontend_integration/test_helpers$1',
    },
    moduleNameMapperEE: {
      '^ee_else_ce_test_helpers(/.*)$': '<rootDir>/ee/spec/frontend_integration/test_helpers$1',
    },
  }),
};
