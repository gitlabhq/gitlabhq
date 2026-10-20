import { unescape } from 'lodash-es';
import { createLink } from './dependency_linker_util';

const PYPI_URL = 'https://pypi.org/project/';
const openTag = '<span class="">';

const PACKAGE_REGEX = new RegExp(
  /*
   * Detects package names at the start of a line inside of content that is highlighted by Highlight.js.
   * Matches a PEP 508 name only when the next character ends it (a version specifier,
   * extras bracket, direct-reference `@`, whitespace or end of line), so comments,
   * options, paths and VCS or URL schemes never match.
   * Example: '<span class="">requests&gt;=2.0,&lt;3</span>'
   * Group 1 (packageName): 'requests'
   */
  `^${openTag}([a-z0-9][a-z0-9._-]*)(?=[\\s&<=~!;\\[@]|$)`,
  'gim',
);

const URL_REGEX = new RegExp(
  /*
   * Detects lines that consist of a URL, which pip installs directly.
   * The match runs to whitespace or the closing tag rather than stopping at an
   * ampersand, so a query string whose separators arrive escaped stays whole.
   * Example: '<span class="">https://example.com/pkg.tar.gz?a=1&amp;b=2</span>'
   * Group 1 (url): 'https://example.com/pkg.tar.gz?a=1&amp;b=2'
   */
  `^${openTag}(https?://[^\\s<]+)`,
  'gm',
);

export default (result) => {
  return result.value
    .replace(
      PACKAGE_REGEX,
      (_, packageName) => `${openTag}${createLink(`${PYPI_URL}${packageName}/`, packageName)}`,
    )
    .replace(URL_REGEX, (_, url) => {
      const unescapedUrl = unescape(url);

      return `${openTag}${createLink(unescapedUrl, unescapedUrl)}`;
    });
};
