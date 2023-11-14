const baseConfig = require('./jest.config.base');

module.exports = {
  ...baseConfig('spec/frontend', {
    roots: ['<rootDir>/scripts/lib/', '<rootDir>/spec/frontend/'],
  }),
  testMatch: [],
};
