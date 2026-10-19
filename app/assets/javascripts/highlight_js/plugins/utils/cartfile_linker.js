import { unescape } from 'lodash-es';
import { createLink } from './dependency_linker_util';

const GITHUB_URL = 'https://github.com/';
const GITHUB_KEYWORD = 'github';
const openTag = '<span class="">';
const quote = '&quot;';

const URL_DEPENDENCY_REGEX = new RegExp(
  /*
   * Detects URL origins inside of content that is highlighted by Highlight.js.
   * The URL runs to the closing quote rather than stopping at an ampersand, so a
   * query string whose separators arrive escaped stays whole.
   * Example: '<span class="">git &quot;https://example.com/git-error-translations.git&quot;</span>'
   * Group 1 (prefix): '<span class="">git '
   * Group 2 (url): 'https://example.com/git-error-translations.git'
   */
  `^(${openTag}\\s*(?:${GITHUB_KEYWORD}|git|binary)\\s+)${quote}(https?://[^\\s<]+?)${quote}`,
  'gm',
);

const GITHUB_DEPENDENCY_REGEX = new RegExp(
  /*
   * Detects GitHub repository origins inside of content that is highlighted by Highlight.js
   * Example: '<span class="">github &quot;ReactiveCocoa/ReactiveCocoa&quot; >= 2.3.1</span>'
   * Group 1 (prefix): '<span class="">github '
   * Group 2 (repo): 'ReactiveCocoa/ReactiveCocoa'
   */
  `^(${openTag}\\s*${GITHUB_KEYWORD}\\s+)${quote}([^/&\\s]+/[^/&\\s]+)${quote}`,
  'gm',
);

export default (result) => {
  return result.value
    .replace(URL_DEPENDENCY_REGEX, (_, prefix, url) => {
      const unescapedUrl = unescape(url);

      return `${prefix}${quote}${createLink(unescapedUrl, unescapedUrl)}${quote}`;
    })
    .replace(
      GITHUB_DEPENDENCY_REGEX,
      (_, prefix, repo) => `${prefix}${quote}${createLink(`${GITHUB_URL}${repo}`, repo)}${quote}`,
    );
};
