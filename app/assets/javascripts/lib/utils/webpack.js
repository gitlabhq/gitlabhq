import { joinPaths } from '~/lib/utils/url_utility';

/**
 * Tell webpack to load assets from origin so that web workers don't break
 * See https://gitlab.com/gitlab-org/gitlab/-/issues/321656 for a fix
 */
export function resetServiceWorkersPublicPath() {
  // __webpack_public_path__ is a global variable that can be used to adjust
  // the webpack publicPath setting at runtime.
  // see: https://webpack.js.org/guides/public-path/
  const relativeRootPath = (gon && gon.relative_url_root) || '';
  const webpackAssetPath = joinPaths(relativeRootPath, '/assets/webpack/');
  __webpack_public_path__ = webpackAssetPath; // eslint-disable-line babel/camelcase
}
