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

// eslint-disable-next-line import/no-commonjs
module.exports = {
  testMatch: ['<rootDir>/spec/frontend/**/*_spec.js'],
  moduleFileExtensions: ['js', 'json', 'vue'],
  moduleNameMapper: {
    '^~(.*)$': '<rootDir>/app/assets/javascripts$1',
    '^helpers(.*)$': '<rootDir>/spec/frontend/helpers$1',
  },
  collectCoverageFrom: ['<rootDir>/app/assets/javascripts/**/*.{js,vue}'],
  coverageDirectory: '<rootDir>/coverage-frontend/',
  coverageReporters: ['json', 'lcov', 'text-summary', 'clover'],
  cacheDirectory: '<rootDir>/tmp/cache/jest',
  modulePathIgnorePatterns: ['<rootDir>/.yarn-cache/'],
  reporters,
  setupTestFrameworkScriptFile: '<rootDir>/spec/frontend/test_setup.js',
  restoreMocks: true,
  transform: {
    '^.+\\.js$': 'babel-jest',
    '^.+\\.vue$': 'vue-jest',
  },
};
