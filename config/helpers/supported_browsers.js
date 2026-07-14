const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const { ROOT_PATH } = require('../webpack.constants');

const supportedBrowsers = fs.readFileSync(path.join(ROOT_PATH, '.browserslistrc'), 'utf-8');
const supportedBrowsersHash = crypto.createHash('sha256').update(supportedBrowsers).digest('hex');

module.exports = { supportedBrowsersHash };
