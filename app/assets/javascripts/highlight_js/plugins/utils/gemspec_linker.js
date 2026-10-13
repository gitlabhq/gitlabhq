import { createLink, generateHLJSOpenTag } from './dependency_linker_util';

const GEM_URL = 'https://rubygems.org/gems/';
const methodRegex = '.*add_dependency.*|.*add_runtime_dependency.*|.*add_development_dependency.*';
const openTagRegex = generateHLJSOpenTag('string', '(&.*;)');
const closeTagRegex = '&.*</span>';

const DEPENDENCY_REGEX = new RegExp(
  /*
   * Detects gemspec dependencies inside of content that is highlighted by Highlight.js
   * Example: s.add_dependency(<span class="hljs-string">&#x27;rugged&#x27;</span>, <span class="hljs-string">&#x27;~&gt; 0.24.0&#x27;</span>)
   *
   * Group 1 (method)     :  s.add_dependency(
   * Group 2 (delimiter)  :  &#x27;
   * Group 3 (packageName):  rugged
   * Group 4 (closeTag)   :  &#x27;</span>
   * Group 5 (rest)       :  	, <span class="hljs-string">&#x27;~&gt; 0.24.0&#x27;</span>)
   */
  `(${methodRegex})${openTagRegex}(.*)(${closeTagRegex})(.*${closeTagRegex})`,
  'gm',
);

// eslint-disable-next-line max-params
const handleReplace = (method, delimiter, packageName, closeTag, rest) => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const openTag = generateHLJSOpenTag('string linked', delimiter);
  const href = `${GEM_URL}${packageName}`;
  const packageLink = createLink(href, packageName);

  return `${method}${openTag}${packageLink}${closeTag}${rest}`;
};

export default (result) => {
  return result.value.replace(
    DEPENDENCY_REGEX,
    // eslint-disable-next-line max-params
    (_, method, delimiter, packageName, closeTag, rest) =>
      handleReplace(method, delimiter, packageName, closeTag, rest),
  );
};
