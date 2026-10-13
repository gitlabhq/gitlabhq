const fs = require('fs');
const path = require('path');
const crypto = require('./patched_crypto');

const CACHE_PATHS = [
  './config/webpack.config.js',
  './config/webpack.vendor.config.js',
  './package.json',
  './yarn.lock',
];

const resolvePath = (file) => path.resolve(__dirname, '../..', file);
const readFile = (file) => fs.readFileSync(file);
const fileHash = (buffer) => crypto.createHash('sha256').update(buffer).digest('hex');

// patch-package patches rewrite node_modules after install, so the DLL built from
// e.g. the Vue runtime changes without package.json or yarn.lock changing.
const patchFiles = () => {
  const dir = resolvePath('./patches');
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((file) => file.endsWith('.patch'))
    .sort()
    .map((file) => path.join(dir, file));
};

module.exports = () => {
  const fileBuffers = [...CACHE_PATHS.map(resolvePath), ...patchFiles()].map(readFile);
  return fileHash(Buffer.concat(fileBuffers)).substr(0, 12);
};
