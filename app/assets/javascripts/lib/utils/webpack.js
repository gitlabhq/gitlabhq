import { joinPaths } from '~/lib/utils/url_utility';

// tell webpack to load assets from origin so that web workers don't break
export function resetServiceWorkersPublicPath() {
  // __webpack_public_path__ is a global variable that can be used to adjust
  // the webpack publicPath setting at runtime.
  // see: https://webpack.js.org/guides/public-path/
  const relativeRootPath = (gon && gon.relative_url_root) || '';
  const webpackAssetPath = joinPaths(relativeRootPath, '/assets/webpack/');
  __webpack_public_path__ = webpackAssetPath; // eslint-disable-line babel/camelcase

  // monaco-editor-webpack-plugin currently (incorrectly) references the
  // public path as a property of `window`.  Once this is fixed upstream we
  // can remove this line
  // see: https://github.com/Microsoft/monaco-editor-webpack-plugin/pull/63
  window.__webpack_public_path__ = webpackAssetPath; // eslint-disable-line
}
