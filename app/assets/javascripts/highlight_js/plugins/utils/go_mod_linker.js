import { createLink } from './dependency_linker_util';

const GO_PACKAGE_URL = 'https://pkg.go.dev/';
const openTag = '<span class="">';
const MODULE_PATH = '[a-z0-9][a-z0-9.-]*\\.[a-z]{2,}(?:/[\\w.~-]+)*';
const VERSION = 'v\\d+\\.\\d+\\.\\d+(?:-[\\w.-]+)?(?:\\+[\\w.-]+)?';

const DEPENDENCY_REGEX = new RegExp(
  /*
   * Detects module paths, optionally followed by a version, inside of content that is highlighted by Highlight.js
   * Example: '<span class="">	github.com/BurntSushi/toml v0.3.1 // indirect</span>'
   * Group 1 (prefix): '<span class="">	'
   * Group 2 (modulePath): 'github.com/BurntSushi/toml'
   * Group 3 (separator): ' '
   * Group 4 (version): 'v0.3.1'
   */
  `^(${openTag}\\s*(?:(?:module|require|replace|exclude|tool)\\s+)?)(${MODULE_PATH})(?:(\\s+)(${VERSION}))?(?=[\\s<]|$)`,
  'gm',
);

// eslint-disable-next-line max-params
const handleReplace = (prefix, modulePath, separator, version) => {
  const href = version
    ? `${GO_PACKAGE_URL}${modulePath}@${version}`
    : `${GO_PACKAGE_URL}${modulePath}`;
  // Reuse the separator so a tab is preserved, not collapsed to a space.
  const versionSuffix = version ? `${separator}${version}` : '';

  return `${prefix}${createLink(href, modulePath)}${versionSuffix}`;
};

export default (result) => {
  // eslint-disable-next-line max-params
  return result.value.replace(DEPENDENCY_REGEX, (_, prefix, modulePath, separator, version) =>
    handleReplace(prefix, modulePath, separator, version),
  );
};
