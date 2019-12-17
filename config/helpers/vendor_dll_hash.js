const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const CACHE_PATHS = [
  './config/webpack.config.js',
  './config/webpack.vendor.config.js',
  './package.json',
  './yarn.lock',
];

const resolvePath = file => path.resolve(__dirname, '../..', file);
const readFile = file => fs.readFileSync(file);
const fileHash = buffer =>
  crypto
    .createHash('md5')
    .update(buffer)
    .digest('hex');

module.exports = () => {
  const fileBuffers = CACHE_PATHS.map(resolvePath).map(readFile);
  return fileHash(Buffer.concat(fileBuffers)).substr(0, 12);
};
