const baseConfig = require('./jest.config.base');

const config = baseConfig('spec/frontend/msw_integration/', {
  roots: ['<rootDir>/spec/frontend/msw_integration', '<rootDir>/spec/frontend/'],
  rootsEE: ['<rootDir>/ee/spec/frontend/msw_integration/'],
  rootsJH: ['<rootDir>/jh/spec/frontend/msw_integration/'],
});

module.exports = {
  ...config,
  testPathIgnorePatterns: [],
  setupFiles: ['<rootDir>/spec/frontend/msw_integration/polyfills.js'],
  setupFilesAfterEnv: [
    ...config.setupFilesAfterEnv,
    '<rootDir>/spec/frontend/__helpers__/shared_test_setup.js',
  ],
  fakeTimers: {
    enableGlobally: false,
  },
  testTimeout: process.env.CI ? 20000 : 7000,
};
