/**
 * This is the first script loaded by webpack's runtime. It is used to manually configure
 * config.output.publicPath to account for relative_url_root or CDN settings which cannot be
 * baked-in to our webpack bundles.
 *
 * Note: This file should be at the top of an entry point and _cannot_ be moved to
 * e.g. the `window` scope, because it needs to be executed in the scope of webpack.
 */

// eslint-disable-next-line camelcase
if (gon && gon.webpack_public_path && typeof __webpack_public_path__ !== 'undefined') {
  __webpack_public_path__ = gon.webpack_public_path; // eslint-disable-line camelcase
}
