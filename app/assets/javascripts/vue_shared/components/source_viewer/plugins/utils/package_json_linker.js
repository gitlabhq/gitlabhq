import { joinPaths } from '~/lib/utils/url_utility';
import { NPM_URL } from '../../constants';
import { createLink, generateHLJSOpenTag } from './dependency_linker_util';

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

const handleReplace = (original, packageName, version, dependenciesToLink) => {
  const href = joinPaths(NPM_URL, packageName);
  const packageLink = createLink(href, packageName);
  const versionLink = createLink(href, version);
  const closeAndOpenTag = `${closeTag}: ${attrOpenTag}`;
  const dependencyToLink = dependenciesToLink[packageName];

  if (dependencyToLink && dependencyToLink === version) {
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
