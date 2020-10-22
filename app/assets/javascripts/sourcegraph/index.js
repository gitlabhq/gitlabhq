import { joinPaths } from '~/lib/utils/url_utility';

function loadScript(path) {
  const script = document.createElement('script');
  script.type = 'application/javascript';
  script.src = path;
  script.defer = true;
  document.head.appendChild(script);
}

/**
 * Loads the Sourcegraph integration for support for Sourcegraph extensions and
 * code intelligence.
 */
export default function initSourcegraph() {
  const { url } = gon.sourcegraph || {};

  if (!url) {
    return;
  }

  const base = gon.asset_host || gon.gitlab_url;
  const assetsUrl = joinPaths(base, '/assets/webpack/sourcegraph/');
  const scriptPath = joinPaths(assetsUrl, 'scripts/integration.bundle.js');

  window.SOURCEGRAPH_ASSETS_URL = assetsUrl;
  window.SOURCEGRAPH_URL = url;
  window.SOURCEGRAPH_INTEGRATION = 'gitlab-integration';

  loadScript(scriptPath);
}
