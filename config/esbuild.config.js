const browserslist = require('browserslist');
const esbuild = require('esbuild');

const ESBUILD_SUPPORTED_TARGETS = new Set([
  'chrome',
  'edge',
  'firefox',
  'hermes',
  'ie',
  'ios',
  'node',
  'opera',
  'rhino',
  'safari',
]);

const parseBrowserslist = (browserslistResult) => {
  return browserslistResult.map((browsers) => {
    const [family, version] = browsers.split(' ');
    let normalizedVersion = version;

    // browserslist can return a range: safari15.2-15.4
    if (version.indexOf('-') >= -1) {
      // we take the lowest version
      [normalizedVersion] = version.split('-');
    }

    return {
      family,
      version: normalizedVersion,
    };
  });
};

const mapBrowserslistToESBuildTarget = (browsersList) => {
  return parseBrowserslist(browsersList)
    .filter(({ family, version }) => {
      if (!ESBUILD_SUPPORTED_TARGETS.has(family)) {
        console.warning('Unknown ESBuild target %s, version %s', family, version);
        return false;
      }

      return true;
    })
    .map(({ family, version }) => {
      return `${family}${version}`;
    });
};

module.exports = {
  target: mapBrowserslistToESBuildTarget(browserslist()),
  supported: {
    'optional-chain': false,
    'nullish-coalescing': false,
    'class-static-field': false,
    'class-field': false,
  },
  implementation: esbuild,
  /**
   * It's necessary to tell esbuild to use the 'js' loader
   * because esbuild cannot auto-detect which loader to use
   * based on the .vue extension.
   */
  loader: 'js',
};
