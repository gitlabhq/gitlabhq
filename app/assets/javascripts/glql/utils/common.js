import { upperFirst, lowerCase } from 'lodash';

export const extractGroupOrProject = (url = window.location.href) => {
  let fullPath = url
    .replace(window.location.origin, '')
    .split('/-/')[0]
    .replace(new RegExp(`^${gon.relative_url_root}/`), '/');

  const isGroup = fullPath.startsWith('/groups');
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
