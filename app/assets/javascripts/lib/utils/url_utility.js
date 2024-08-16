import { getGlobalAlerts, setGlobalAlerts } from './global_alerts';

export const DASH_SCOPE = '-';

export const PATH_SEPARATOR = '/';
const PATH_SEPARATOR_LEADING_REGEX = new RegExp(`^${PATH_SEPARATOR}+`);
const PATH_SEPARATOR_ENDING_REGEX = new RegExp(`${PATH_SEPARATOR}+$`);
const SHA_REGEX = /[\da-f]{40}/gi;

// GitLab default domain (override in jh)
export const DOMAIN = 'gitlab.com';

// Following URLs will be overwritten in jh
export const FORUM_URL = `https://forum.${DOMAIN}/`; // forum.gitlab.com
export const DOCS_URL = `https://docs.${DOMAIN}`; // docs.gitlab.com

// About GitLab default host
export const PROMO_HOST = `about.${DOMAIN}`; // about.gitlab.com

// About Gitlab default url
export const PROMO_URL = `https://${PROMO_HOST}`;

// eslint-disable-next-line no-restricted-syntax
export const DOCS_URL_IN_EE_DIR = `${DOCS_URL}/ee`;

/**
 * Reset the cursor in a Regex so that multiple uses before a recompile don't fail
 * @param {RegExp} regex
 */
function resetRegExp(regex) {
  regex.lastIndex = 0; /* eslint-disable-line no-param-reassign */

  return regex;
}

/**
 * Returns the absolute pathname for a relative or absolute URL string.
 * @param {string} url
 *
 * A few examples of inputs and outputs:
 * 1) 'http://a.com/b/c/d' => '/b/c/d'
 * 2) '/b/c/d' => '/b/c/d'
 * 3) 'b/c/d' => '/b/c/d' or '[path]/b/c/d' depending of the current path of the
 *    document.location
 */
export const parseUrlPathname = (url) => {
  const { pathname } = new URL(url, document.location.href);
  return pathname;
};

/**
 * Returns a decoded url parameter value
 * - Treats '+' as '%20'
 * @param {string} val
 */
function decodeUrlParameter(val) {
  return decodeURIComponent(val.replace(/\+/g, '%20'));
}

/**
 * Safely encodes a string to be used as a path
 *
 * Note: This function DOES encode typical URL parts like ?, =, &, #, and +
 * If you need to use search parameters or URL fragments, they should be
 *     added AFTER calling this function, not before.
 *
 * Usecase: An image filename is stored verbatim, and you need to load it in
 *     the browser.
 *
 * Example: /some_path/file #1.jpg      ==> /some_path/file%20%231.jpg
 * Example: /some-path/file! Final!.jpg ==> /some-path/file%21%20Final%21.jpg
 *
 * Essentially, if a character *could* present a problem in a URL, it's escaped
 *     to the hexadecimal representation instead. This means it's a bit more
 *     aggressive than encodeURIComponent: that built-in function doesn't
 *     encode some characters that *could* be problematic, so this function
 *     adds them (#, !, ~, *, ', (, and )).
 *     Additionally, encodeURIComponent *does* encode `/`, but we want safer
 *     URLs, not non-functional URLs, so this function DEcodes slashes ('%2F').
 *
 * @param {String} potentiallyUnsafePath
 * @returns {String}
 */
export function encodeSaferUrl(potentiallyUnsafePath) {
  const unencode = ['%2F'];
  const encode = ['#', '!', '~', '\\*', "'", '\\(', '\\)'];
  let saferPath = encodeURIComponent(potentiallyUnsafePath);

  unencode.forEach((code) => {
    saferPath = saferPath.replace(new RegExp(code, 'g'), decodeURIComponent(code));
  });
  encode.forEach((code) => {
    const encodedValue = code
      .codePointAt(code.length - 1)
      .toString(16)
      .toUpperCase();

    saferPath = saferPath.replace(new RegExp(code, 'g'), `%${encodedValue}`);
  });

  return saferPath;
}

/**
 * @param {string} path
 */
export function cleanLeadingSeparator(path) {
  return path.replace(PATH_SEPARATOR_LEADING_REGEX, '');
}

/**
 * @param {string} path
 */
export function cleanEndingSeparator(path) {
  return path.replace(PATH_SEPARATOR_ENDING_REGEX, '');
}

/**
 * Safely joins the given paths which might both start and end with a `/`
 *
 * Example:
 * - `joinPaths('abc/', '/def') === 'abc/def'`
 * - `joinPaths(null, 'abc/def', 'zoo) === 'abc/def/zoo'`
 *
 * @param  {...string} paths
 * @returns {string}
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
 * @param {string} url
 * @param {Object} [options]
 * @param {boolean} [options.spreadArrays] - split array values into separate key/value-pairs
 * @param {boolean} [options.sort] - alphabetically sort params in the returned url (in asc order, i.e., a-z)
 */
export function mergeUrlParams(params, url, options = {}) {
  const { spreadArrays = false, sort = false } = options;
  const re = /^([^?#]*)(\?[^#]*)?(.*)/;
  let merged = {};
  const [, fullpath, query, fragment] = url.match(re);

  if (query) {
    merged = query
      .substr(1)
      .split('&')
      .reduce((memo, part) => {
        if (part.length) {
          const kv = part.split('=');
          let key = decodeUrlParameter(kv[0]);
          const value = decodeUrlParameter(kv.slice(1).join('='));
          if (spreadArrays && key.endsWith('[]')) {
            key = key.slice(0, -2);
            if (!Array.isArray(memo[key])) {
              return { ...memo, [key]: [value] };
            }
            memo[key].push(value);

            return memo;
          }

          return { ...memo, [key]: value };
        }

        return memo;
      }, {});
  }

  Object.assign(merged, params);

  const mergedKeys = sort ? Object.keys(merged).sort() : Object.keys(merged);

  const newQuery = mergedKeys
    .filter((key) => merged[key] !== null && merged[key] !== undefined)
    .map((key) => {
      let value = merged[key];
      const encodedKey = encodeURIComponent(key);
      if (spreadArrays && Array.isArray(value)) {
        value = merged[key]
          .map((arrayValue) => encodeURIComponent(arrayValue))
          .join(`&${encodedKey}[]=`);
        return `${encodedKey}[]=${value}`;
      }
      return `${encodedKey}=${encodeURIComponent(value)}`;
    })
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

  const removableParams = skipEncoding ? params : params.map((param) => encodeURIComponent(param));

  const updatedQuery = query
    .split('&')
    .filter((paramPair) => {
      const [foundParam] = paramPair.split('=');
      return removableParams.indexOf(foundParam) < 0;
    })
    .join('&');

  const writableQuery = updatedQuery.length > 0 ? `?${updatedQuery}` : '';
  const writableFragment = fragment ? `#${fragment}` : '';
  return `${root}${writableQuery}${writableFragment}`;
}

/**
 * Returns value after the '#' in the location hash
 * @returns Current value of the hash, undefined if not set
 */
export const getLocationHash = () => window.location.hash?.split('#')[1];

/**
 * Returns a boolean indicating whether the URL hash contains the given string value
 * @param {string} hashName
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

export function updateHistory({ state = {}, title = '', url, replace = false, win = window } = {}) {
  if (win.history) {
    if (replace) {
      win.history.replaceState(state, title, url);
    } else {
      win.history.pushState(state, title, url);
    }
  }
}

export const escapeFileUrl = (fileUrl) => encodeURIComponent(fileUrl).replace(/%2F/g, '/');

export function webIDEUrl(route = undefined) {
  let returnUrl = `${gon.relative_url_root || ''}/-/ide/`;

  if (route) {
    returnUrl += `project${route.replace(new RegExp(`^${gon.relative_url_root || ''}/`), '/')}`;
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
  return /^\/(?!\/)/.test(url);
}

/**
 * Returns true if url is a base64 data URL
 *
 * @param {String} url
 */
export function isBase64DataUrl(url) {
  return /^data:[.\w+-]+\/[.\w+-]+;base64,/.test(url);
}

/**
 * Returns true if url is a blob: type url
 *
 * @param {String} url
 */
export function isBlobUrl(url) {
  return /^blob:/.test(url);
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
 * Returns a list of path segments of the given URL instance.
 *
 * @param {URL} url - URL instance (not a string!)
 * @returns {Array<string>} List of path segments of the given URL
 */
export function pathSegments(url) {
  const pathname = url.pathname.endsWith(PATH_SEPARATOR) ? url.pathname.slice(0, -1) : url.pathname;
  return pathname.split(PATH_SEPARATOR).slice(1);
}

/**
 * Returns `true` if the `url` is an external URL.
 * The query and hash of the url are ignored.
 *
 * @param {string} url
 * @returns {boolean}
 */
export function isExternal(url) {
  const gitlabURL = new URL(gon.gitlab_url);
  const newURL = new URL(url, window.location.href);

  if (gitlabURL.origin !== newURL.origin) {
    return true;
  }

  const gitlabURLpathSegments = pathSegments(gitlabURL);
  const newURLpathSegments = pathSegments(newURL);

  const isInternal = gitlabURLpathSegments.every(
    (pathSegment, i) => pathSegment === newURLpathSegments[i],
  );

  return !isInternal;
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
  url.pathname = url.pathname.replace(/\/\/+/g, '/');
  return absolute ? url.href : decodeURIComponent(url.pathname);
}

/**
 * Checks if the provided URL is a valid URL. Valid URLs are
 * - absolute URLs (`http(s)://...`)
 * - root-relative URLs (`/path/...`)
 * - parsable by the `URL` constructor
 * - has http or https protocol
 *
 * Relative URLs (`../path`), queries (`?...`), and hashes (`#...`) are not
 * considered valid.
 *
 * @param {String} url that will be checked
 * @returns {Boolean}
 */
export function isValidURL(url) {
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

/**
 * Returns a normalized url
 *
 * https://gitlab.com/foo/../baz => https://gitlab.com/baz
 *
 * @param {String} url - URL to be transformed
 * @param {String?} baseUrl - current base URL
 * @returns {String}
 */
export const getNormalizedURL = (url, baseUrl) => {
  const base = baseUrl || getBaseURL();
  try {
    return new URL(url, base).href;
  } catch (e) {
    return '';
  }
};

export function getWebSocketProtocol() {
  return window.location.protocol.replace('http', 'ws');
}

export function getWebSocketUrl(path) {
  return `${getWebSocketProtocol()}//${joinPaths(window.location.host, path)}`;
}

const splitPath = (path = '') => path.replace(/^\?/, '').split('&');

export const urlParamsToArray = (path = '') =>
  splitPath(path)
    .filter((param) => param.length > 0)
    .map((param) => {
      const split = param.split('=');
      return [decodeURI(split[0]), split[1]].join('=');
    });

export const getUrlParamsArray = () => urlParamsToArray(window.location.search);

/**
 * Convert search query into an object
 *
 * @param {String} query from "document.location.search"
 * @param {Object} options
 * @param {Boolean?} options.gatherArrays - gather array values into an Array
 * @param {Boolean?} options.legacySpacesDecode - (deprecated) plus symbols (+) are not replaced with spaces, false by default
 * @returns {Object}
 *
 * ex: "?one=1&two=2" into {one: 1, two: 2}
 */
export function queryToObject(query, { gatherArrays = false, legacySpacesDecode = false } = {}) {
  const removeQuestionMarkFromQuery = String(query).startsWith('?') ? query.slice(1) : query;
  return removeQuestionMarkFromQuery.split('&').reduce((accumulator, curr) => {
    const [key, value] = curr.split('=');
    if (value === undefined) {
      return accumulator;
    }

    const decodedValue = legacySpacesDecode ? decodeURIComponent(value) : decodeUrlParameter(value);
    const decodedKey = legacySpacesDecode ? decodeURIComponent(key) : decodeUrlParameter(key);

    if (gatherArrays && decodedKey.endsWith('[]')) {
      const decodedArrayKey = decodedKey.slice(0, -2);

      if (!Array.isArray(accumulator[decodedArrayKey])) {
        accumulator[decodedArrayKey] = [];
      }

      accumulator[decodedArrayKey].push(decodedValue);
    } else {
      accumulator[decodedKey] = decodedValue;
    }

    return accumulator;
  }, {});
}

/**
 * This function accepts the `name` of the param to parse in the url
 * if the name does not exist this function will return `null`
 * otherwise it will return the value of the param key provided
 *
 * @param {String} name
 * @param {String?} urlToParse
 * @returns value of the parameter as string
 */
export const getParameterByName = (name, query = window.location.search) => {
  return queryToObject(query)[name] || null;
};

/**
 * Convert search query object back into a search query
 *
 * @param {Object?} params that needs to be converted
 * @returns {String}
 *
 * ex: {one: 1, two: 2} into "one=1&two=2"
 *
 */
export function objectToQuery(params = {}) {
  return Object.keys(params)
    .map((k) => `${encodeURIComponent(k)}=${encodeURIComponent(params[k])}`)
    .join('&');
}

/**
 * Sets query params for a given URL
 * It adds new query params, updates existing params with a new value and removes params with value null/undefined
 *
 * @param {Object} params The query params to be set/updated
 * @param {String} url The url to be operated on
 * @param {Boolean} clearParams Indicates whether existing query params should be removed or not
 * @param {Boolean} railsArraySyntax When enabled, changes the array syntax from `keys=` to `keys[]=` according to Rails conventions
 * @returns {String} A copy of the original with the updated query params
 */
export const setUrlParams = (
  params,
  url = window.location.href,
  clearParams = false,
  railsArraySyntax = false,
  decodeParams = false,
  // eslint-disable-next-line max-params
) => {
  const urlObj = new URL(url);
  const queryString = urlObj.search;
  const searchParams = clearParams ? new URLSearchParams('') : new URLSearchParams(queryString);

  Object.keys(params).forEach((key) => {
    if (params[key] === null || params[key] === undefined) {
      searchParams.delete(key);
    } else if (Array.isArray(params[key])) {
      const keyName = railsArraySyntax ? `${key}[]` : key;
      if (params[key].length === 0) {
        searchParams.delete(keyName);
      } else {
        params[key].forEach((val, idx) => {
          if (idx === 0) {
            searchParams.set(keyName, val);
          } else {
            searchParams.append(keyName, val);
          }
        });
      }
    } else {
      searchParams.set(key, params[key]);
    }
  });

  urlObj.search = decodeParams
    ? decodeURIComponent(searchParams.toString())
    : searchParams.toString();

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

/**
 * Strips the filename from the given path by removing every non-slash character from the end of the
 * passed parameter.
 * @param {string} path
 */
export function stripPathTail(path = '') {
  return path.replace(/[^/]+$/, '');
}

export function getURLOrigin(url) {
  if (!url) {
    return window.location.origin;
  }

  try {
    return new URL(url).origin;
  } catch (e) {
    return null;
  }
}

/**
 * Returns `true` if the given `url` resolves to the same origin the page is served
 * from; otherwise, returns `false`.
 *
 * The `url` may be absolute or relative.
 *
 * @param {string} url The URL to check.
 * @returns {boolean}
 */
export function isSameOriginUrl(url) {
  if (typeof url !== 'string') {
    return false;
  }

  const { origin } = window.location;

  try {
    return new URL(url, origin).origin === origin;
  } catch {
    // Invalid URLs cannot have the same origin
    return false;
  }
}

/**
 * Returns a URL to WebIDE considering the current user's position in
 * repository's tree. If not MR `iid` has been passed, the URL is fetched
 * from the global `gl.webIDEPath`.
 *
 * @param sourceProjectFullPath Source project's full path. Used in MRs
 * @param targetProjectFullPath Target project's full path. Used in MRs
 * @param iid                   MR iid
 * @returns {string}
 */

export function constructWebIDEPath({
  sourceProjectFullPath,
  targetProjectFullPath = '',
  iid,
} = {}) {
  if (!iid || !sourceProjectFullPath) {
    return window.gl?.webIDEPath;
  }
  return mergeUrlParams(
    {
      target_project: sourceProjectFullPath !== targetProjectFullPath ? targetProjectFullPath : '',
    },
    webIDEUrl(`/${sourceProjectFullPath}/merge_requests/${iid}`),
  );
}

/**
 * Examples
 *
 * http://gitlab.com => gitlab.com
 * https://gitlab.com => gitlab.com
 *
 * @param {String} url
 * @returns A url without a protocol / scheme
 */
export const removeUrlProtocol = (url) => url.replace(/^\w+:\/?\/?/, '');

/**
 * Examples
 *
 * https://www.gitlab.com/path/ => https://www.gitlab.com/path
 * https://www.gitlab.com/?query=search => https://www.gitlab.com?query=search
 * https://www.gitlab.com/#fragment => https://www.gitlab.com#fragment
 *
 * @param {String} url
 * @returns A URL that does not have a path that ends with slash
 */
export const removeLastSlashInUrlPath = (url) =>
  url.replace(/\/$/, '').replace(/\/(\?|#){1}([^/]*)$/, '$1$2');

/**
 * Navigates to a URL.
 *
 * If destination is a querystring, it will be automatically transformed into a fully qualified URL.
 * If the URL is not valid (see isValidURL implementation), this function will log an exception into Sentry.
 * If the URL is external it calls window.open so it has no referrer header or reference to its opener.
 *
 * @param {*} destination - url to navigate to. This can be a fully qualified URL or a querystring.
 * @param {*} openWindow - if true, open a new window or tab
 */
export function visitUrl(destination, openWindow = false) {
  let url = destination;

  if (destination.startsWith('?')) {
    const currentUrl = new URL(window.location.href);
    currentUrl.search = destination;
    url = currentUrl.toString();
  }

  if (!isValidURL(url)) {
    throw new RangeError(`Only http and https protocols are allowed: ${url}`);
  }

  if (isExternal(url)) {
    const target = openWindow ? '_blank' : '_self';
    // Sets window.opener to null and avoids leaking referrer information.
    // eslint-disable-next-line no-restricted-properties
    window.open(url, target, 'noreferrer');
  } else if (openWindow) {
    // eslint-disable-next-line no-restricted-properties
    window.open(url);
  } else {
    window.location.assign(url);
  }
}

/**
 * Navigates to a URL and display alerts.
 *
 * If destination is a querystring, it will be automatically transformed into a fully qualified URL.
 * If the URL is not valid (see isValidURL implementation), this function will log an exception into Sentry.
 *
 * @param {*} destination - url to navigate to. This can be a fully qualified URL or a querystring.
 * @param {{id: String, title?: String, message: String, variant: String, dismissible?: Boolean, persistOnPages?: String[]}[]} alerts - Alerts to display
 */
export function visitUrlWithAlerts(destination, alerts) {
  setGlobalAlerts([...getGlobalAlerts(), ...alerts]);
  visitUrl(destination);
}

export function refreshCurrentPage() {
  visitUrl(window.location.href);
}

// Adds a ref_type param to the path if refType is available
export function buildURLwithRefType({ base = window.location.origin, path, refType = null }) {
  const url = new URL('', base);
  url.pathname = path; // This assignment does proper _escapes_

  if (refType) {
    url.searchParams.set('ref_type', refType.toLowerCase());
  } else {
    url.searchParams.delete('ref_type');
  }
  return url.pathname + url.search;
}

export function stripRelativeUrlRootFromPath(path) {
  const relativeUrlRoot = joinPaths(window.gon.relative_url_root, '/');

  // If we have no relative url root or path doesn't start with it, just return the path
  if (relativeUrlRoot === '/' || !path.startsWith(relativeUrlRoot)) {
    return path;
  }

  return joinPaths('/', path.substring(relativeUrlRoot.length));
}
