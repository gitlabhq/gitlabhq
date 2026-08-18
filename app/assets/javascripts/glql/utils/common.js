import { upperFirst, lowerCase } from 'lodash-es';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';

export const extractGroupOrProject = (url = window.location.href) => {
  // These are URL parsing operations on dynamic values, not ideal but acceptable
  /* eslint-disable @gitlab/no-hardcoded-urls */
  let fullPath = url
    .replace(window.location.origin, '')
    .split('/-/')[0]
    .replace(new RegExp(`^${gon.relative_url_root}/`), '/');

  const isGroup = fullPath.startsWith('/groups');
  /* eslint-enable @gitlab/no-hardcoded-urls */
  fullPath = fullPath.replace(/^\/groups\//, '').replace(/^\//g, '');
  if (isGroup) return { group: fullPath };
  if (fullPath) return { project: fullPath };
  return {};
};

export const toSentenceCase = (str) => {
  if (str === 'id' || str === 'iid') return str.toUpperCase();
  return upperFirst(lowerCase(str));
};

/**
 * Returns the relative path from one namespace to another.
 * Used for project / group namespaces.
 *
 * @param {string} source - The starting path
 * @param {string} target - The target path
 * @returns {string} The relative namespace from 'source' to 'target'
 */
export const relativeNamespace = (source, target) => {
  if (!source) return target;
  if (!target || source === target) return '';

  const sourceSegments = source.split('/');
  const targetSegments = target.split('/');
  let commonPrefixLength = 0;

  for (let i = 0; i < Math.min(sourceSegments.length, targetSegments.length); i += 1) {
    if (sourceSegments[i] !== targetSegments[i]) break;
    commonPrefixLength += 1;
  }

  if (commonPrefixLength === 0) return target;
  return targetSegments.slice(commonPrefixLength).join('/') || target;
};

/**
 * Wraps a GLQL query in a fenced glql block, the form used to embed it in Markdown.
 *
 * @param {string} query - The GLQL query source
 * @returns {string} The query wrapped in a fenced glql block
 */
export const wrapQueryInGlqlBlock = (query) =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `\`\`\`glql\n${query}\n\`\`\``;

/**
 * Copies a GLQL query to the clipboard, wrapped in a fenced glql block so that it
 * can be pasted straight back into Markdown.
 *
 * @param {string} query - The GLQL query source
 * @param {HTMLElement} [container] - Container for the fallback textarea used in non-secure
 * contexts. Defaults to the document body, which does not work when copying from a modal.
 */
export const copyQuerySource = (query, container = document.body) =>
  copyToClipboard(wrapQueryInGlqlBlock(query), container);
