/**
 * This is the first script loaded by webpack's runtime. It is used to manually configure
 * config.output.publicPath to account for relative_url_root or CDN settings which cannot be
 * baked-in to our webpack bundles.
 */

if (gon && gon.webpack_public_path) {
  __webpack_public_path__ = gon.webpack_public_path; // eslint-disable-line camelcase
}
