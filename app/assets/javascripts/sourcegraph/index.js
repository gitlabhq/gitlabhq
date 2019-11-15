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

  const assetsUrl = new URL('/assets/webpack/sourcegraph/', window.location.href);
  const scriptPath = new URL('scripts/integration.bundle.js', assetsUrl).href;

  window.SOURCEGRAPH_ASSETS_URL = assetsUrl.href;
  window.SOURCEGRAPH_URL = url;
  window.SOURCEGRAPH_INTEGRATION = 'gitlab-integration';

  loadScript(scriptPath);
}
