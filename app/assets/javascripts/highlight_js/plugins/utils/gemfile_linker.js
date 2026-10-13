import { createLink, generateHLJSOpenTag } from './dependency_linker_util';

const GEM_URL = 'https://rubygems.org/gems/';
const GEM_STRING = 'gem </span>';
const delimiter = '&#39;';
const stringOpenTag = generateHLJSOpenTag('string', delimiter);

const DEPENDENCY_REGEX = new RegExp(
  /*
   * Detects dependencies inside of content that is highlighted by Highlight.js
   * Example: 'gem </span><span class="hljs-string">&#39;paranoia&#39;'
   * Group 1 (packageName)     :  'paranoia'
   */
  `${GEM_STRING}${stringOpenTag}(.+?(?=${delimiter}))`,
  'gm',
);

const handleReplace = (packageName) => {
  const href = `${GEM_URL}${packageName}`;
  const packageLink = createLink(href, packageName);
  return `${GEM_STRING}${stringOpenTag}${packageLink}`;
};
export default (result) => {
  return result.value.replace(DEPENDENCY_REGEX, (_, packageName) => handleReplace(packageName));
};
