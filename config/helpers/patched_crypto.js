/**
 * Webpack 4 uses md4 internally because it is fast.
 * Some loaders also use md5 directly.
 * It is not available systems with FIPS enabled node.
 *
 * This is a hack to monkey patch the crypto function to use
 * another algorithm if md4 or md5 is expected.
 *
 * https://github.com/webpack/webpack/issues/13572#issuecomment-923736472
 *
 * This hack can be removed once we upgrade to webpack v5 as
 * it includes native support for configuring hash options:
 * https://github.com/webpack/webpack/pull/14306
 */
const crypto = require('crypto');

const cryptoHashOriginal = crypto.createHash;

crypto.createHash = (algorithm) =>
  cryptoHashOriginal(['md4', 'md5'].includes(algorithm) ? 'sha256' : algorithm);

module.exports = crypto;
