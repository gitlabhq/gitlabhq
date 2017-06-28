/**
 * This is the first script loaded by webpack's runtime. It is used to manually configure
 * config.output.publicPath to account for relative_url_root settings which cannot be baked-in
 * to our webpack bundles.
 */

if (gon && gon.relative_url_root) {
  // this assumes config.output.publicPath is an absolute path
  const basePath = gon.relative_url_root.replace(/\/$/, '');

  // eslint-disable-next-line camelcase, no-undef
  __webpack_public_path__ = basePath + __webpack_public_path__;
}
