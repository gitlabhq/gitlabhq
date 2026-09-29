import { getBaseURL, mergeUrlParams, relativePathToAbsolute } from '~/lib/utils/url_utility';

/**
 * Generates an absolute permalink path with proper handling of URL hash
 *
 * @param {String} permalinkPath - The relative permalink path
 * @param {String} hash - The URL hash (after #)
 * @param {Object} queryParams - Additional query parameters to preserve (e.g., { blame: '1' })
 * @returns {String} - The absolute permalink path with hash handling
 */
export const getAbsolutePermalinkPath = (permalinkPath, inputHash, queryParams = {}) => {
  const baseAbsolutePath = relativePathToAbsolute(permalinkPath, getBaseURL());

  const hash = inputHash || '';

  const params = Object.fromEntries(
    Object.entries(queryParams).filter(([, v]) => v !== undefined && v !== null && v !== ''),
  );

  // Ensure hash starts with # if it doesn't already
  let normalizedHash = '';
  if (hash.trim()) {
    normalizedHash = hash.startsWith('#') ? hash : `#${hash}`;
  }

  const hasParams = Object.keys(params).length > 0;
  const url = hasParams
    ? mergeUrlParams(params, `${baseAbsolutePath}${normalizedHash}`)
    : `${baseAbsolutePath}${normalizedHash}`;

  return url;
};
