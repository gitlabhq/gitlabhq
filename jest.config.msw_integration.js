const baseConfig = require('./jest.config.base');

const USE_VUE_3 = process.env.VUE_VERSION === '3';

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
    ...(USE_VUE_3 ? ['<rootDir>/spec/frontend/vue_compat_test_setup.js'] : []),
    '<rootDir>/spec/frontend/__helpers__/shared_test_setup.js',
    ...config.setupFilesAfterEnv,
  ],
  fakeTimers: {
    enableGlobally: false,
  },
  testTimeout: process.env.CI ? 20000 : 7000,
};
