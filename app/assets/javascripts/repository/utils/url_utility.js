import { joinPaths, escapeFileUrl, removeParams } from '~/lib/utils/url_utility';

/**
 * Extracts the first path segment from a repository route path.
 * Typically used to extract the ref (branch/tag name) from a route.
 *
 * @param {string} path - The route path (e.g., '/master', '/develop/app/models', '/feature%2Fbranch')
 * @returns {string|null} The first path segment, or null if path is empty
 *
 * @example
 * extractFirstPathSegment('/master') => 'master'
 * extractFirstPathSegment('/develop/app/models') => 'develop'
 * extractFirstPathSegment('/feature%2Fbranch') => 'feature%2Fbranch' (encoded)
 * extractFirstPathSegment('/') => null
 */
export function extractFirstPathSegment(path) {
  const pathWithoutLeadingSlash = path.replace(/^\/+/, '');
  const firstSegment = pathWithoutLeadingSlash.split('/')[0];

  if (!firstSegment) {
    return null;
  }

  return firstSegment;
}

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

  // Normalize '/' to empty string for repository root to avoid trailing slash
  const normalizedPath = path === '/' ? '' : path;

  url.pathname = joinPaths(
    removeParams(['ref_type'], historyLink),
    normalizedPath ? escapeFileUrl(normalizedPath) : '',
  );

  if (refType && !url.searchParams.get('ref_type')) {
    url.searchParams.set('ref_type', refType);
  }

  return url;
}
