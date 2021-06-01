const fs = require('fs');
const path = require('path');
const { memoize } = require('lodash');
const { PATH_ASSETS } = require('./constants');
const { die } = require('./utils');

const listAssetsDir = memoize(() => fs.readdirSync(PATH_ASSETS));

const getCSSPath = (prefix) => {
  const matcher = new RegExp(`^${prefix}-[^-]+\\.css$`);
  const cssPath = listAssetsDir().find((x) => matcher.test(x));

  if (!cssPath) {
    die(
      `Could not find the CSS asset matching "${prefix}". Have you run "scripts/frontend/startup_css/setup.sh"?`,
    );
  }

  return path.join(PATH_ASSETS, cssPath);
};

module.exports = { getCSSPath };
