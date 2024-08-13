import { createLink, generateHLJSOpenTag } from './dependency_linker_util';

const PACKAGIST_URL = 'https://packagist.org/packages/';
const DRUPAL_URL = 'https://www.drupal.org/project/';

const attrOpenTag = generateHLJSOpenTag('attr');
const stringOpenTag = generateHLJSOpenTag('string');
const closeTag = '&quot;</span>';
const DRUPAL_PROJECT_SEPARATOR = 'drupal/';
const DEPENDENCY_REGEX = new RegExp(
  /*
   * Detects dependencies inside of content that is highlighted by Highlight.js
   * Example: <span class="hljs-attr">&quot;composer/installers&quot;</span><span class="hljs-punctuation">:</span> <span class="hljs-string">&quot;^1.2&quot;</span>
   * Group 1:  composer/installers
   * Group 2:  ^1.2
   */
  `${attrOpenTag}([^/]+/[^/]+.)${closeTag}.*${stringOpenTag}(.*[0-9].*)(${closeTag})`,
  'gm',
);

// eslint-disable-next-line max-params
const handleReplace = (original, packageName, version, dependenciesToLink) => {
  const isDrupalDependency = packageName.includes(DRUPAL_PROJECT_SEPARATOR);
  const href = isDrupalDependency
    ? `${DRUPAL_URL}${packageName.split(DRUPAL_PROJECT_SEPARATOR)[1]}`
    : `${PACKAGIST_URL}${packageName}`;
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
  const rawParsed = JSON.parse(raw);

  const dependenciesToLink = {
    ...rawParsed.require,
    ...rawParsed['require-dev'],
  };

  return result.value.replace(DEPENDENCY_REGEX, (original, packageName, version) =>
    handleReplace(original, packageName, version, dependenciesToLink),
  );
};
