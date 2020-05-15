const baseConfig = require('./jest.config.base');

module.exports = {
  ...baseConfig('spec/frontend_integration'),
};
