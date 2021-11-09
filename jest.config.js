const fs = require('fs');
const IS_JH = require('./config/helpers/is_jh_env');
const baseConfig = require('./jest.config.base');

// TODO: Remove existsSync once jh has added jest.config.js
if (IS_JH && fs.existsSync('./jh/jest.config.js')) {
  // eslint-disable-next-line global-require, import/no-unresolved
  module.exports = require('./jh/jest.config');
} else {
  module.exports = {
    ...baseConfig('spec/frontend'),
  };
}
