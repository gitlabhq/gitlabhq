const fs = require('fs');
const IS_JH = require('./config/helpers/is_jh_env');
const baseConfig = require('./jest.config.base');

// TODO: Remove existsSync once jh has added jest.config.js
if (IS_JH && fs.existsSync('./jh/jest.config.js')) {
  // We can't be explicit with eslint-disable rules because in JH it'll pass import/no-unresolved
  // eslint-disable-next-line
  module.exports = require('./jh/jest.config');
} else {
  module.exports = {
    ...baseConfig('spec/frontend', {
      roots: ['<rootDir>/spec/frontend/'],
      rootsEE: ['<rootDir>/ee/spec/frontend/'],
      rootsJH: ['<rootDir>/jh/spec/frontend/'],
    }),
  };
}
