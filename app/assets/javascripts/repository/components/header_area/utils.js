import { getBaseURL, relativePathToAbsolute } from '~/lib/utils/url_utility';
import { getPageParamValue, getPageSearchString } from '~/blob/utils';

/**
 * Generates an absolute permalink path with proper handling of URL hash
 *
 * @param {String} permalinkPath - The relative permalink path
 * @param {String} hash - The URL hash (after #)
 * @returns {String} - The absolute permalink path with hash handling
 */
export const getAbsolutePermalinkPath = (permalinkPath, inputHash) => {
  const baseAbsolutePath = relativePathToAbsolute(permalinkPath, getBaseURL());

  const hash = inputHash || '';

  const page = getPageParamValue(hash);
  const searchString = getPageSearchString(baseAbsolutePath, page);

  // Ensure hash starts with # if it doesn't already
  let normalizedHash = '';
  if (hash.trim()) {
    normalizedHash = hash.startsWith('#') ? hash : `#${hash}`;
  }
  return `${baseAbsolutePath}${searchString}${normalizedHash}`;
};
