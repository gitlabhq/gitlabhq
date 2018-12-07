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
  moduleNameMapper: {
    '^~(.*)$': '<rootDir>/app/assets/javascripts$1',
  },
  collectCoverageFrom: ['<rootDir>/app/assets/javascripts/**/*.{js,vue}'],
  coverageDirectory: '<rootDir>/coverage-frontend/',
  coverageReporters: ['json', 'lcov', 'text-summary', 'clover'],
  cacheDirectory: '<rootDir>/tmp/cache/jest',
  modulePathIgnorePatterns: ['<rootDir>/.yarn-cache/'],
  reporters,
  rootDir: '..', // necessary because this file is in the config/ subdirectory
};
