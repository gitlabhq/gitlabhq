// tell webpack to load assets from origin so that web workers don't break
// eslint-disable-next-line import/prefer-default-export
export function resetServiceWorkersPublicPath() {
  // __webpack_public_path__ is a global variable that can be used to adjust
  // the webpack publicPath setting at runtime.
  // see: https://webpack.js.org/guides/public-path/
  const relativeRootPath = (gon && gon.relative_url_root) || '';
  const webpackAssetPath = `${relativeRootPath}/assets/webpack/`;
  window.__webpack_public_path__ = webpackAssetPath; // eslint-disable-line
}
