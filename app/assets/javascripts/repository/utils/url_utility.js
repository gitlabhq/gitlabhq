import { joinPaths, escapeFileUrl, removeParams } from '~/lib/utils/url_utility';

/**
 * Encodes a repository path for use in URLs, handling special characters that could
 * interfere with URL parsing while preserving path separators and commonly used characters.
 *
 * This method works like encodeURI() but also encodes the '#' character which
 * can cause issues in GitLab repository URLs by being interpreted as a fragment identifier.
 *
 * @param {string} path - The file path to encode
 * @returns {string} The encoded path safe for use in URLs
 */
export function encodeRepositoryPath(path) {
  if (!path) return '';

  // Start with encodeURI to handle most characters while preserving /
  let encoded = encodeURI(path);

  // Additional characters that need encoding for GitLab repository paths
  // but are not encoded by encodeURI()
  encoded = encoded.replace(/#/g, '%23');

  return encoded;
}

export function generateHistoryUrl(historyLink, path, refType) {
  const url = new URL(window.location.href);

  url.pathname = joinPaths(
    removeParams(['ref_type'], historyLink),
    path ? escapeFileUrl(path) : '',
  );

  if (refType && !url.searchParams.get('ref_type')) {
    url.searchParams.set('ref_type', refType);
  }

  return url;
}
