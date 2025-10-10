/**
 * Performs basic sanity checks on a URL before attempting connection:
 * - is not empty
 * - has no spaces
 * - has http, git or https protocol
 * - has a domain with at least one dot
 *
 * Does not guarantee the URL is fully valid or reachable.
 *
 * @param {String} url that will be checked
 * @returns {Boolean}
 */

export function isReasonableURL(url) {
  if (!url || typeof url !== 'string') {
    return false;
  }

  if (/\s/.test(url)) {
    return false;
  }

  const pattern = /^(https?|git):\/\/[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+/;

  return pattern.test(url);
}
