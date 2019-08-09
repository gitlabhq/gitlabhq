import { join as joinPaths } from 'path';

// Returns an array containing the value(s) of the
// of the key passed as an argument
export function getParameterValues(sParam, url = window.location) {
  const sPageURL = decodeURIComponent(new URL(url).search.substring(1));

  return sPageURL.split('&').reduce((acc, urlParam) => {
    const sParameterName = urlParam.split('=');

    if (sParameterName[0] === sParam) {
      acc.push(sParameterName[1].replace(/\+/g, ' '));
    }

    return acc;
  }, []);
}

// @param {Object} params - url keys and value to merge
// @param {String} url
export function mergeUrlParams(params, url) {
  const re = /^([^?#]*)(\?[^#]*)?(.*)/;
  const merged = {};
  const urlparts = url.match(re);

  if (urlparts[2]) {
    urlparts[2]
      .substr(1)
      .split('&')
      .forEach(part => {
        if (part.length) {
          const kv = part.split('=');
          merged[decodeURIComponent(kv[0])] = decodeURIComponent(kv.slice(1).join('='));
        }
      });
  }

  Object.assign(merged, params);

  const query = Object.keys(merged)
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(merged[key])}`)
    .join('&');

  return `${urlparts[1]}?${query}${urlparts[3]}`;
}

/**
 * Removes specified query params from the url by returning a new url string that no longer
 * includes the param/value pair. If no url is provided, `window.location.href` is used as
 * the default value.
 *
 * @param {string[]} params - the query param names to remove
 * @param {string} [url=windowLocation().href] - url from which the query param will be removed
 * @returns {string} A copy of the original url but without the query param
 */
export function removeParams(params, url = window.location.href) {
  const [rootAndQuery, fragment] = url.split('#');
  const [root, query] = rootAndQuery.split('?');

  if (!query) {
    return url;
  }

  const encodedParams = params.map(param => encodeURIComponent(param));
  const updatedQuery = query
    .split('&')
    .filter(paramPair => {
      const [foundParam] = paramPair.split('=');
      return encodedParams.indexOf(foundParam) < 0;
    })
    .join('&');

  const writableQuery = updatedQuery.length > 0 ? `?${updatedQuery}` : '';
  const writableFragment = fragment ? `#${fragment}` : '';
  return `${root}${writableQuery}${writableFragment}`;
}

export function getLocationHash(url = window.location.href) {
  const hashIndex = url.indexOf('#');

  return hashIndex === -1 ? null : url.substring(hashIndex + 1);
}

/**
 * Apply the fragment to the given url by returning a new url string that includes
 * the fragment. If the given url already contains a fragment, the original fragment
 * will be removed.
 *
 * @param {string} url - url to which the fragment will be applied
 * @param {string} fragment - fragment to append
 */
export const setUrlFragment = (url, fragment) => {
  const [rootUrl] = url.split('#');
  const encodedFragment = encodeURIComponent(fragment.replace(/^#/, ''));
  return `${rootUrl}#${encodedFragment}`;
};

export function visitUrl(url, external = false) {
  if (external) {
    // Simulate `target="blank" rel="noopener noreferrer"`
    // See https://mathiasbynens.github.io/rel-noopener/
    const otherWindow = window.open();
    otherWindow.opener = null;
    otherWindow.location = url;
  } else {
    window.location.href = url;
  }
}

export function refreshCurrentPage() {
  visitUrl(window.location.href);
}

export function redirectTo(url) {
  return window.location.assign(url);
}

export function webIDEUrl(route = undefined) {
  let returnUrl = `${gon.relative_url_root || ''}/-/ide/`;
  if (route) {
    returnUrl += `project${route.replace(new RegExp(`^${gon.relative_url_root || ''}`), '')}`;
  }
  return returnUrl;
}

/**
 * Returns current base URL
 */
export function getBaseURL() {
  const { protocol, host } = window.location;
  return `${protocol}//${host}`;
}

/**
 * Returns true if url is an absolute or root-relative URL
 *
 * @param {String} url
 */
export function isAbsoluteOrRootRelative(url) {
  return /^(https?:)?\//.test(url);
}

/**
 * Checks if the provided URL is a safe URL (absolute http(s) or root-relative URL)
 *
 * @param {String} url that will be checked
 * @returns {Boolean}
 */
export function isSafeURL(url) {
  if (!isAbsoluteOrRootRelative(url)) {
    return false;
  }

  try {
    const parsedUrl = new URL(url, getBaseURL());
    return ['http:', 'https:'].includes(parsedUrl.protocol);
  } catch (e) {
    return false;
  }
}

export function getWebSocketProtocol() {
  return window.location.protocol.replace('http', 'ws');
}

export function getWebSocketUrl(path) {
  return `${getWebSocketProtocol()}//${joinPaths(window.location.host, path)}`;
}

export { joinPaths };
