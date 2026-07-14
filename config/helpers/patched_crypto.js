/**
 * OpenSSL 3 (Node 20+) and FIPS builds reject md4/md5, which Webpack and some
 * loaders/plugins still request for cache keys. Patches createHash to substitute
 * sha256. Imported for this side effect by webpack.config.js and rspack.config.mjs.
 * https://github.com/webpack/webpack/issues/13572#issuecomment-923736472
 */
const crypto = require('crypto');

const cryptoHashOriginal = crypto.createHash;

crypto.createHash = (algorithm) =>
  cryptoHashOriginal(['md4', 'md5'].includes(algorithm) ? 'sha256' : algorithm);

module.exports = crypto;
