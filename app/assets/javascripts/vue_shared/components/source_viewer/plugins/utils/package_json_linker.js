import { unescape } from 'lodash';
import { createLink, generateHLJSOpenTag } from './dependency_linker_util';

const NPM_URL = 'https://npmjs.com/package/';
const attrOpenTag = generateHLJSOpenTag('attr');
const stringOpenTag = generateHLJSOpenTag('string');
const closeTag = '&quot;</span>';
const DEPENDENCY_REGEX = new RegExp(
  /*
   * Detects dependencies inside of content that is highlighted by Highlight.js
   * Example: <span class="hljs-attr">&quot;@babel/core&quot;</span><span class="hljs-punctuation">:</span> <span class="hljs-string">&quot;^7.18.5&quot;</span>
   * Group 1:  @babel/core
   * Group 2:  ^7.18.5
   */
  `${attrOpenTag}(.*)${closeTag}.*${stringOpenTag}(.*[0-9].*)(${closeTag})`,
  'gm',
);

// eslint-disable-next-line max-params
const handleReplace = (original, packageName, version, dependenciesToLink) => {
  const unescapedPackageName = unescape(packageName);
  const unescapedVersion = unescape(version);
  const href = `${NPM_URL}${unescapedPackageName}`;
  const packageLink = createLink(href, unescapedPackageName);
  const versionLink = createLink(href, unescapedVersion);
  const closeAndOpenTag = `${closeTag}: ${attrOpenTag}`;
  const dependencyToLink = dependenciesToLink[unescapedPackageName];

  if (dependencyToLink && dependencyToLink === unescapedVersion) {
    return `${attrOpenTag}${packageLink}${closeAndOpenTag}${versionLink}${closeTag}`;
  }

  return original;
};

export default (result, raw) => {
  const { dependencies, devDependencies, peerDependencies, optionalDependencies } = JSON.parse(raw);

  const dependenciesToLink = {
    ...dependencies,
    ...devDependencies,
    ...peerDependencies,
    ...optionalDependencies,
  };

  return result.value.replace(DEPENDENCY_REGEX, (original, packageName, version) =>
    handleReplace(original, packageName, version, dependenciesToLink),
  );
};
