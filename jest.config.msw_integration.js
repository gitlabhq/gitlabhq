const baseConfig = require('./jest.config.base');
const IS_JH = require('./config/helpers/is_jh_env');

const USE_VUE_3 = process.env.VUE_VERSION === '3';

const MSW_SETUP = '<rootDir>/ee/spec/frontend/msw_integration/test_setup.js';

// MSW integration tests are EE-only, but `path` stays CE-relative so
// baseConfig's EE/JH auto-prefixing derives correct `ee/` and `jh/` globs (the
// empty CE glob matches nothing). `isEE: true` forces the EE aliases; the
// derived CE `test_setup.js` is swapped for the EE one below.
const config = baseConfig('spec/frontend/msw_integration', {
  isEE: true,
  roots: [
    '<rootDir>/ee/spec/frontend/msw_integration/',
    ...(IS_JH ? ['<rootDir>/jh/spec/frontend/msw_integration/'] : []),
    '<rootDir>/ee/spec/frontend/',
    '<rootDir>/spec/frontend/',
  ],
});

module.exports = {
  ...config,
  testPathIgnorePatterns: [],
  setupFiles: ['<rootDir>/ee/spec/frontend/msw_integration/polyfills.js'],
  setupFilesAfterEnv: [
    ...(USE_VUE_3 ? ['<rootDir>/spec/frontend/vue_compat_test_setup.js'] : []),
    '<rootDir>/spec/frontend/__helpers__/shared_test_setup.js',
    ...config.setupFilesAfterEnv.map((entry) =>
      entry.endsWith('/spec/frontend/msw_integration/test_setup.js') ? MSW_SETUP : entry,
    ),
  ],
  fakeTimers: {
    enableGlobally: false,
  },
  testTimeout: process.env.CI ? 20000 : 7000,
};
