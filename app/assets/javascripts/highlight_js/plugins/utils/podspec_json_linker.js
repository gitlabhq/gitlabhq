import { createLink, generateHLJSOpenTag, getObjectKeysByKeyName } from './dependency_linker_util';

const COCOAPODS_URL = 'https://cocoapods.org/pods/';
const beginString = generateHLJSOpenTag('attr');
const endString =
  '&quot;</span><span class="hljs-punctuation">:</span><span class=""> </span><span class="hljs-punctuation">\\[';

const DEPENDENCY_REGEX = new RegExp(
  /*
   * Detects dependencies inside of content that is highlighted by Highlight.js
   * Example: <span class="hljs-attr">&quot;AFNetworking/Security&quot;</span><span class="hljs-punctuation">:</span><span class=""> </span><span class="hljs-punctuation"> [
   * Group 1:  AFNetworking/Serialization
   */
  `${beginString}([^/]+/?[^/]+.)${endString}`,
  'gm',
);

const handleReplace = (original, dependency, dependenciesToLink) => {
  if (dependenciesToLink.includes(dependency)) {
    const href = `${COCOAPODS_URL}${dependency.split('/')[0]}`;
    const link = createLink(href, dependency);
    return `${beginString}${link}${endString.replace('\\', '')}`;
  }
  return original;
};

export default (result, raw) => {
  const dependenciesToLink = getObjectKeysByKeyName(JSON.parse(raw), 'dependencies', []);
  return result.value.replace(DEPENDENCY_REGEX, (original, dependency) =>
    handleReplace(original, dependency, dependenciesToLink),
  );
};
