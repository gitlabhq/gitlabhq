const baseConfig = require('./jest.config.base');
const IS_JH = require('./config/helpers/is_jh_env');

const USE_VUE_3 = process.env.VUE_VERSION === '3';

const INTEGRATION_SETUP = '<rootDir>/ee/spec/frontend/integration/test_setup.js';

// Frontend integration tests are EE-only, but `path` stays CE-relative so
// baseConfig's EE/JH auto-prefixing derives correct `ee/` and `jh/` globs (the
// empty CE glob matches nothing). `isEE: true` forces the EE aliases; the
// derived CE `test_setup.js` is swapped for the EE one below.
const config = baseConfig('spec/frontend/integration', {
  isEE: true,
  roots: [
    '<rootDir>/ee/spec/frontend/integration/',
    ...(IS_JH ? ['<rootDir>/jh/spec/frontend/integration/'] : []),
    '<rootDir>/ee/spec/frontend/',
    '<rootDir>/spec/frontend/',
  ],
});

// `msw` dependencies that ship ESM only, so Jest has to transform them.
const MSW_ESM_DEPENDENCIES = ['rettime', 'until-async', '@open-draft/.*'];

module.exports = {
  ...config,
  transformIgnorePatterns: config.transformIgnorePatterns.map((pattern) =>
    pattern.replace('node_modules/(?!(', `node_modules/(?!(${MSW_ESM_DEPENDENCIES.join('|')}|`),
  ),
  testPathIgnorePatterns: [],
  setupFiles: ['<rootDir>/ee/spec/frontend/integration/polyfills.js'],
  setupFilesAfterEnv: [
    ...(USE_VUE_3 ? ['<rootDir>/spec/frontend/vue_compat_test_setup.js'] : []),
    '<rootDir>/spec/frontend/__helpers__/shared_test_setup.js',
    ...config.setupFilesAfterEnv.map((entry) =>
      entry.endsWith('/spec/frontend/integration/test_setup.js') ? INTEGRATION_SETUP : entry,
    ),
  ],
  fakeTimers: {
    enableGlobally: false,
  },
  testTimeout: process.env.CI ? 20000 : 7000,
};
