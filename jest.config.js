/* eslint-disable filenames/match-regex */

const reporters = ['default'];

if (process.env.CI) {
  reporters.push([
    'jest-junit',
    {
      output: './junit_jest.xml',
    },
  ]);
}

const config = {
  testMatch: ['<rootDir>/spec/frontend/**/*_spec.js'],
  moduleNameMapper: {
    '^~(.*)$': '<rootDir>/app/assets/javascripts$1',
  },
  collectCoverageFrom: ['<rootDir>/app/assets/javascripts/**/*.{js,vue}'],
  coverageDirectory: '<rootDir>/coverage-frontend/',
  cacheDirectory: '<rootDir>/tmp/jest-cache',
  setupTestFrameworkScriptFile: '<rootDir>/spec/frontend/test_setup.js',
  modulePathIgnorePatterns: ['<rootDir>/.yarn-cache/'],
  reporters,
};

const selfCheckPath = '<rootDir>/spec/frontend/self_check';
if (process.env.JEST_SELF_CHECK) {
  config.testMatch = [`${selfCheckPath}/*_spec.js`];
  config.reporters = [`${selfCheckPath}/reporter`];
} else {
  config.testPathIgnorePatterns = [selfCheckPath];
}

// eslint-disable-next-line import/no-commonjs
module.exports = config;
