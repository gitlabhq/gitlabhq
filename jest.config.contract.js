const baseConfig = require('./jest.config.base');

module.exports = () => {
  return {
    testMatch: baseConfig('spec/contracts/consumer').testMatch,
    transform: {
      '^.+\\.js$': 'babel-jest',
    },
    testEnvironment: baseConfig.testEnvironment,
  };
};
