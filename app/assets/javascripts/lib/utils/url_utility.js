const PATH_SEPARATOR = '/';
const PATH_SEPARATOR_LEADING_REGEX = new RegExp(`^${PATH_SEPARATOR}+`);
const PATH_SEPARATOR_ENDING_REGEX = new RegExp(`${PATH_SEPARATOR}+$`);
const SHA_REGEX = /[\da-f]{40}/gi;

// Reset the cursor in a Regex so that multiple uses before a recompile don't fail
function resetRegExp(regex) {
  regex.lastIndex = 0; /* eslint-disable-line no-param-reassign */

  return regex;
}

// Returns a decoded url parameter value
// - Treats '+' as '%20'
function decodeUrlParameter(val) {
  return decodeURIComponent(val.replace(/\+/g, '%20'));
}

function cleanLeadingSeparator(path) {
  return path.replace(PATH_SEPARATOR_LEADING_REGEX, '');
}

function cleanEndingSeparator(path) {
  return path.replace(PATH_SEPARATOR_ENDING_REGEX, '');
}

/**
 * Safely joins the given paths which might both start and end with a `/`
 *
 * Example:
 * - `joinPaths('abc/', '/def') === 'abc/def'`
 * - `joinPaths(null, 'abc/def', 'zoo) === 'abc/def/zoo'`
 *
 * @param  {...String} paths
 * @returns {String}
 */
export function joinPaths(...paths) {
  return paths.reduce((acc, path) => {
    if (!path) {
      return acc;
    }
    if (!acc) {
      return path;
    }

    return [cleanEndingSeparator(acc), PATH_SEPARATOR, cleanLeadingSeparator(path)].join('');
  }, '');
}

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

/**
 * Merges a URL to a set of params replacing value for
 * those already present.
 *
 * Also removes `null` param values from the resulting URL.
 *
 * @param {Object} params - url keys and value to merge
 * @param {String} url
 */
export function mergeUrlParams(params, url) {
  const re = /^([^?#]*)(\?[^#]*)?(.*)/;
  const merged = {};
  const [, fullpath, query, fragment] = url.match(re);

  if (query) {
    query
      .substr(1)
      .split('&')
      .forEach(part => {
        if (part.length) {
          const kv = part.split('=');
          merged[decodeUrlParameter(kv[0])] = decodeUrlParameter(kv.slice(1).join('='));
        }
      });
  }

  Object.assign(merged, params);

  const newQuery = Object.keys(merged)
    .filter(key => merged[key] !== null)
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(merged[key])}`)
    .join('&');

  if (newQuery) {
    return `${fullpath}?${newQuery}${fragment}`;
  }
  return `${fullpath}${fragment}`;
}

/**
 * Removes specified query params from the url by returning a new url string that no longer
 * includes the param/value pair. If no url is provided, `window.location.href` is used as
 * the default value.
 *
 * @param {string[]} params - the query param names to remove
 * @param {string} [url=windowLocation().href] - url from which the query param will be removed
 * @param {boolean} skipEncoding - set to true when the url does not require encoding
 * @returns {string} A copy of the original url but without the query param
 */
export function removeParams(params, url = window.location.href, skipEncoding = false) {
  const [rootAndQuery, fragment] = url.split('#');
  const [root, query] = rootAndQuery.split('?');

  if (!query) {
    return url;
  }

  const removableParams = skipEncoding ? params : params.map(param => encodeURIComponent(param));

  const updatedQuery = query
    .split('&')
    .filter(paramPair => {
      const [foundParam] = paramPair.split('=');
      return removableParams.indexOf(foundParam) < 0;
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
 * Returns a boolean indicating whether the URL hash contains the given string value
 */
export function doesHashExistInUrl(hashName) {
  const hash = getLocationHash();
  return hash && hash.includes(hashName);
}

export function urlContainsSha({ url = String(window.location) } = {}) {
  return resetRegExp(SHA_REGEX).test(url);
}

export function getShaFromUrl({ url = String(window.location) } = {}) {
  let sha = null;

  if (urlContainsSha({ url })) {
    [sha] = url.match(resetRegExp(SHA_REGEX));
  }

  return sha;
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
    // Simulate `target="_blank" rel="noopener noreferrer"`
    // See https://mathiasbynens.github.io/rel-noopener/
    const otherWindow = window.open();
    otherWindow.opener = null;
    otherWindow.location = url;
  } else {
    window.location.href = url;
  }
}

export function updateHistory({ state = {}, title = '', url, replace = false, win = window } = {}) {
  if (win.history) {
    if (replace) {
      win.history.replaceState(state, title, url);
    } else {
      win.history.pushState(state, title, url);
    }
  }
}

export function refreshCurrentPage() {
  visitUrl(window.location.href);
}

export function redirectTo(url) {
  return window.location.assign(url);
}

export const escapeFileUrl = fileUrl => encodeURIComponent(fileUrl).replace(/%2F/g, '/');

export function webIDEUrl(route = undefined) {
  let returnUrl = `${gon.relative_url_root || ''}/-/ide/`;
  if (route) {
    returnUrl += `project${route.replace(new RegExp(`^${gon.relative_url_root || ''}`), '')}`;
  }
  return escapeFileUrl(returnUrl);
}

/**
 * Returns current base URL
 */
export function getBaseURL() {
  const { protocol, host } = window.location;
  return `${protocol}//${host}`;
}

/**
 * Returns true if url is an absolute URL
 *
 * @param {String} url
 */
export function isAbsolute(url) {
  return /^https?:\/\//.test(url);
}

/**
 * Returns true if url is a root-relative URL
 *
 * @param {String} url
 */
export function isRootRelative(url) {
  return /^\//.test(url);
}

/**
 * Returns true if url is an absolute or root-relative URL
 *
 * @param {String} url
 */
export function isAbsoluteOrRootRelative(url) {
  return isAbsolute(url) || isRootRelative(url);
}

/**
 * Converts a relative path to an absolute or a root relative path depending
 * on what is passed as a basePath.
 *
 * @param {String} path       Relative path, eg. ../img/img.png
 * @param {String} basePath   Absolute or root relative path, eg. /user/project or
 *                            https://gitlab.com/user/project
 */
export function relativePathToAbsolute(path, basePath) {
  const absolute = isAbsolute(basePath);
  const base = absolute ? basePath : `file:///${basePath}`;
  const url = new URL(path, base);
  return absolute ? url.href : decodeURIComponent(url.pathname);
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

/**
 * Convert search query into an object
 *
 * @param {String} query from "document.location.search"
 * @returns {Object}
 *
 * ex: "?one=1&two=2" into {one: 1, two: 2}
 */
export function queryToObject(query) {
  const removeQuestionMarkFromQuery = String(query).startsWith('?') ? query.slice(1) : query;
  return removeQuestionMarkFromQuery.split('&').reduce((accumulator, curr) => {
    const [key, value] = curr.split('=');
    if (value !== undefined) {
      accumulator[decodeURIComponent(key)] = decodeURIComponent(value);
    }
    return accumulator;
  }, {});
}

/**
 * Convert search query object back into a search query
 *
 * @param {Object} obj that needs to be converted
 * @returns {String}
 *
 * ex: {one: 1, two: 2} into "one=1&two=2"
 *
 */
export function objectToQuery(obj) {
  return Object.keys(obj)
    .map(k => `${encodeURIComponent(k)}=${encodeURIComponent(obj[k])}`)
    .join('&');
}

/**
 * Sets query params for a given URL
 * It adds new query params, updates existing params with a new value and removes params with value null/undefined
 *
 * @param {Object} params The query params to be set/updated
 * @param {String} url The url to be operated on
 * @param {Boolean} clearParams Indicates whether existing query params should be removed or not
 * @returns {String} A copy of the original with the updated query params
 */
export const setUrlParams = (params, url = window.location.href, clearParams = false) => {
  const urlObj = new URL(url);
  const queryString = urlObj.search;
  const searchParams = clearParams ? new URLSearchParams('') : new URLSearchParams(queryString);

  Object.keys(params).forEach(key => {
    if (params[key] === null || params[key] === undefined) {
      searchParams.delete(key);
    } else if (Array.isArray(params[key])) {
      params[key].forEach((val, idx) => {
        if (idx === 0) {
          searchParams.set(key, val);
        } else {
          searchParams.append(key, val);
        }
      });
    } else {
      searchParams.set(key, params[key]);
    }
  });

  urlObj.search = searchParams.toString();

  return urlObj.toString();
};

export function urlIsDifferent(url, compare = String(window.location)) {
  return url !== compare;
}

export function getHTTPProtocol(url) {
  if (!url) {
    return window.location.protocol.slice(0, -1);
  }
  const protocol = url.split(':');
  return protocol.length > 1 ? protocol[0] : undefined;
}
