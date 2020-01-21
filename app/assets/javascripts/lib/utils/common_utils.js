/**
 * @module common-utils
 */

import { GlBreakpointInstance as breakpointInstance } from '@gitlab/ui/dist/utils';
import $ from 'jquery';
import axios from './axios_utils';
import { getLocationHash } from './url_utility';
import { convertToCamelCase, convertToSnakeCase } from './text_utility';
import { isObject } from './type_utility';

export const getPagePath = (index = 0) => {
  const page = $('body').attr('data-page') || '';

  return page.split(':')[index];
};

export const getDashPath = (path = window.location.pathname) => path.split('/-/')[1] || null;

export const isInGroupsPage = () => getPagePath() === 'groups';

export const isInProjectPage = () => getPagePath() === 'projects';

export const getProjectSlug = () => {
  if (isInProjectPage()) {
    return $('body').data('project');
  }
  return null;
};

export const getGroupSlug = () => {
  if (isInGroupsPage()) {
    return $('body').data('group');
  }
  return null;
};

export const checkPageAndAction = (page, action) => {
  const pagePath = getPagePath(1);
  const actionPath = getPagePath(2);

  return pagePath === page && actionPath === action;
};

export const isInIssuePage = () => checkPageAndAction('issues', 'show');
export const isInMRPage = () => checkPageAndAction('merge_requests', 'show');
export const isInEpicPage = () => checkPageAndAction('epics', 'show');

export const getCspNonceValue = () => {
  const metaTag = document.querySelector('meta[name=csp-nonce]');
  return metaTag && metaTag.content;
};

export const ajaxGet = url =>
  axios
    .get(url, {
      params: { format: 'js' },
      responseType: 'text',
    })
    .then(({ data }) => {
      $.globalEval(data, { nonce: getCspNonceValue() });
    });

export const rstrip = val => {
  if (val) {
    return val.replace(/\s+$/, '');
  }
  return val;
};

export const updateTooltipTitle = ($tooltipEl, newTitle) =>
  $tooltipEl.attr('title', newTitle).tooltip('_fixTitle');

export const disableButtonIfEmptyField = (fieldSelector, buttonSelector, eventName = 'input') => {
  const field = $(fieldSelector);
  const closestSubmit = field.closest('form').find(buttonSelector);
  if (rstrip(field.val()) === '') {
    closestSubmit.disable();
  }
  // eslint-disable-next-line func-names
  return field.on(eventName, function() {
    if (rstrip($(this).val()) === '') {
      return closestSubmit.disable();
    }
    return closestSubmit.enable();
  });
};

// automatically adjust scroll position for hash urls taking the height of the navbar into account
// https://github.com/twitter/bootstrap/issues/1768
export const handleLocationHash = () => {
  let hash = getLocationHash();
  if (!hash) return;

  // This is required to handle non-unicode characters in hash
  hash = decodeURIComponent(hash);

  const target = document.getElementById(hash) || document.getElementById(`user-content-${hash}`);
  const fixedTabs = document.querySelector('.js-tabs-affix');
  const fixedDiffStats = document.querySelector('.js-diff-files-changed');
  const fixedNav = document.querySelector('.navbar-gitlab');
  const performanceBar = document.querySelector('#js-peek');
  const topPadding = 8;
  const diffFileHeader = document.querySelector('.js-file-title');
  const versionMenusContainer = document.querySelector('.mr-version-menus-container');

  let adjustment = 0;
  if (fixedNav) adjustment -= fixedNav.offsetHeight;

  if (target && target.scrollIntoView) {
    target.scrollIntoView(true);
  }

  if (fixedTabs) {
    adjustment -= fixedTabs.offsetHeight;
  }

  if (fixedDiffStats) {
    adjustment -= fixedDiffStats.offsetHeight;
  }

  if (performanceBar) {
    adjustment -= performanceBar.offsetHeight;
  }

  if (diffFileHeader) {
    adjustment -= diffFileHeader.offsetHeight;
  }

  if (versionMenusContainer) {
    adjustment -= versionMenusContainer.offsetHeight;
  }

  if (isInMRPage()) {
    adjustment -= topPadding;
  }

  setTimeout(() => {
    window.scrollBy(0, adjustment);
  });
};

// Check if element scrolled into viewport from above or below
// Courtesy http://stackoverflow.com/a/7557433/414749
export const isInViewport = (el, offset = {}) => {
  const rect = el.getBoundingClientRect();
  const { top, left } = offset;

  return (
    rect.top >= (top || 0) &&
    rect.left >= (left || 0) &&
    rect.bottom <= window.innerHeight &&
    parseInt(rect.right, 10) <= window.innerWidth
  );
};

export const parseUrl = url => {
  const parser = document.createElement('a');
  parser.href = url;
  return parser;
};

export const parseUrlPathname = url => {
  const parsedUrl = parseUrl(url);
  // parsedUrl.pathname will return an absolute path for Firefox and a relative path for IE11
  // We have to make sure we always have an absolute path.
  return parsedUrl.pathname.charAt(0) === '/' ? parsedUrl.pathname : `/${parsedUrl.pathname}`;
};

const splitPath = (path = '') => path.replace(/^\?/, '').split('&');

export const urlParamsToArray = (path = '') =>
  splitPath(path)
    .filter(param => param.length > 0)
    .map(param => {
      const split = param.split('=');
      return [decodeURI(split[0]), split[1]].join('=');
    });

export const getUrlParamsArray = () => urlParamsToArray(window.location.search);

/**
 * Accepts encoding string which includes query params being
 * sent to URL.
 *
 * @param {string} path Query param string
 *
 * @returns {object} Query params object containing key-value pairs
 *                   with both key and values decoded into plain string.
 */
export const urlParamsToObject = (path = '') =>
  splitPath(path).reduce((dataParam, filterParam) => {
    if (filterParam === '') {
      return dataParam;
    }

    const data = dataParam;
    let [key, value] = filterParam.split('=');
    key = /%\w+/g.test(key) ? decodeURIComponent(key) : key;
    const isArray = key.includes('[]');
    key = key.replace('[]', '');
    value = decodeURIComponent(value.replace(/\+/g, ' '));

    if (isArray) {
      if (!data[key]) {
        data[key] = [];
      }

      data[key].push(value);
    } else {
      data[key] = value;
    }

    return data;
  }, {});

export const isMetaKey = e => e.metaKey || e.ctrlKey || e.altKey || e.shiftKey;

// Identify following special clicks
// 1) Cmd + Click on Mac (e.metaKey)
// 2) Ctrl + Click on PC (e.ctrlKey)
// 3) Middle-click or Mouse Wheel Click (e.which is 2)
export const isMetaClick = e => e.metaKey || e.ctrlKey || e.which === 2;

export const contentTop = () => {
  const perfBar = $('#js-peek').outerHeight() || 0;
  const mrTabsHeight = $('.merge-request-tabs').outerHeight() || 0;
  const headerHeight = $('.navbar-gitlab').outerHeight() || 0;
  const diffFilesChanged = $('.js-diff-files-changed').outerHeight() || 0;
  const isDesktop = breakpointInstance.isDesktop();
  const diffFileTitleBar =
    (isDesktop && $('.diff-file .file-title-flex-parent:visible').outerHeight()) || 0;
  const compareVersionsHeaderHeight = (isDesktop && $('.mr-version-controls').outerHeight()) || 0;

  return (
    perfBar +
    mrTabsHeight +
    headerHeight +
    diffFilesChanged +
    diffFileTitleBar +
    compareVersionsHeaderHeight
  );
};

export const scrollToElement = element => {
  let $el = element;
  if (!(element instanceof $)) {
    $el = $(element);
  }
  const { top } = $el.offset();

  // eslint-disable-next-line no-jquery/no-animate
  return $('body, html').animate(
    {
      scrollTop: top - contentTop(),
    },
    200,
  );
};

/**
 * Returns a function that can only be invoked once between
 * each browser screen repaint.
 * @param {Function} fn
 */
export const debounceByAnimationFrame = fn => {
  let requestId;

  return function debounced(...args) {
    if (requestId) {
      window.cancelAnimationFrame(requestId);
    }
    requestId = window.requestAnimationFrame(() => fn.apply(this, args));
  };
};

/**
  this will take in the `name` of the param you want to parse in the url
  if the name does not exist this function will return `null`
  otherwise it will return the value of the param key provided
*/
export const getParameterByName = (name, urlToParse) => {
  const url = urlToParse || window.location.href;
  const parsedName = name.replace(/[[\]]/g, '\\$&');
  const regex = new RegExp(`[?&]${parsedName}(=([^&#]*)|&|#|$)`);
  const results = regex.exec(url);
  if (!results) return null;
  if (!results[2]) return '';
  return decodeURIComponent(results[2].replace(/\+/g, ' '));
};

const handleSelectedRange = (range, restrictToNode) => {
  // Make sure this range is within the restricting container
  if (restrictToNode && !range.intersectsNode(restrictToNode)) return null;

  // If only a part of the range is within the wanted container, we need to restrict the range to it
  if (restrictToNode && !restrictToNode.contains(range.commonAncestorContainer)) {
    if (!restrictToNode.contains(range.startContainer)) range.setStart(restrictToNode, 0);
    if (!restrictToNode.contains(range.endContainer))
      range.setEnd(restrictToNode, restrictToNode.childNodes.length);
  }

  const container = range.commonAncestorContainer;
  // add context to fragment if needed
  if (container.tagName === 'OL') {
    const parentContainer = document.createElement(container.tagName);
    parentContainer.appendChild(range.cloneContents());
    return parentContainer;
  }
  return range.cloneContents();
};

export const getSelectedFragment = restrictToNode => {
  const selection = window.getSelection();
  if (selection.rangeCount === 0) return null;
  // Most usages of the selection only want text from a part of the page (e.g. discussion)
  if (restrictToNode && !selection.containsNode(restrictToNode, true)) return null;

  const documentFragment = document.createDocumentFragment();
  documentFragment.originalNodes = [];

  for (let i = 0; i < selection.rangeCount; i += 1) {
    const range = selection.getRangeAt(i);
    const handledRange = handleSelectedRange(range, restrictToNode);
    if (handledRange) {
      documentFragment.appendChild(handledRange);
      documentFragment.originalNodes.push(range.commonAncestorContainer);
    }
  }
  if (documentFragment.textContent.length === 0) return null;

  return documentFragment;
};

export const insertText = (target, text) => {
  // Firefox doesn't support `document.execCommand('insertText', false, text)` on textareas
  const { selectionStart, selectionEnd, value } = target;

  const textBefore = value.substring(0, selectionStart);
  const textAfter = value.substring(selectionEnd, value.length);

  const insertedText = text instanceof Function ? text(textBefore, textAfter) : text;
  const newText = textBefore + insertedText + textAfter;

  // eslint-disable-next-line no-param-reassign
  target.value = newText;
  // eslint-disable-next-line no-param-reassign
  target.selectionStart = selectionStart + insertedText.length;

  // eslint-disable-next-line no-param-reassign
  target.selectionEnd = selectionStart + insertedText.length;

  // Trigger autosave
  target.dispatchEvent(new Event('input'));

  // Trigger autosize
  const event = document.createEvent('Event');
  event.initEvent('autosize:update', true, false);
  target.dispatchEvent(event);
};

export const nodeMatchesSelector = (node, selector) => {
  const matches =
    Element.prototype.matches ||
    Element.prototype.matchesSelector ||
    Element.prototype.mozMatchesSelector ||
    Element.prototype.msMatchesSelector ||
    Element.prototype.oMatchesSelector ||
    Element.prototype.webkitMatchesSelector;

  if (matches) {
    return matches.call(node, selector);
  }

  // IE11 doesn't support `node.matches(selector)`

  let { parentNode } = node;

  if (!parentNode) {
    parentNode = document.createElement('div');
    // eslint-disable-next-line no-param-reassign
    node = node.cloneNode(true);
    parentNode.appendChild(node);
  }

  const matchingNodes = parentNode.querySelectorAll(selector);
  return Array.prototype.indexOf.call(matchingNodes, node) !== -1;
};

/**
  this will take in the headers from an API response and normalize them
  this way we don't run into production issues when nginx gives us lowercased header keys
*/
export const normalizeHeaders = headers => {
  const upperCaseHeaders = {};

  Object.keys(headers || {}).forEach(e => {
    upperCaseHeaders[e.toUpperCase()] = headers[e];
  });

  return upperCaseHeaders;
};

/**
  this will take in the getAllResponseHeaders result and normalize them
  this way we don't run into production issues when nginx gives us lowercased header keys
*/
export const normalizeCRLFHeaders = headers => {
  const headersObject = {};
  const headersArray = headers.split('\n');

  headersArray.forEach(header => {
    const keyValue = header.split(': ');

    // eslint-disable-next-line prefer-destructuring
    headersObject[keyValue[0]] = keyValue[1];
  });

  return normalizeHeaders(headersObject);
};

/**
 * Parses pagination object string values into numbers.
 *
 * @param {Object} paginationInformation
 * @returns {Object}
 */
export const parseIntPagination = paginationInformation => ({
  perPage: parseInt(paginationInformation['X-PER-PAGE'], 10),
  page: parseInt(paginationInformation['X-PAGE'], 10),
  total: parseInt(paginationInformation['X-TOTAL'], 10),
  totalPages: parseInt(paginationInformation['X-TOTAL-PAGES'], 10),
  nextPage: parseInt(paginationInformation['X-NEXT-PAGE'], 10),
  previousPage: parseInt(paginationInformation['X-PREV-PAGE'], 10),
});

/**
 * Given a string of query parameters creates an object.
 *
 * @example
 * `scope=all&page=2` -> { scope: 'all', page: '2'}
 * `scope=all` -> { scope: 'all' }
 * ``-> {}
 * @param {String} query
 * @returns {Object}
 */
export const parseQueryStringIntoObject = (query = '') => {
  if (query === '') return {};

  return query.split('&').reduce((acc, element) => {
    const val = element.split('=');
    Object.assign(acc, {
      [val[0]]: decodeURIComponent(val[1]),
    });
    return acc;
  }, {});
};

/**
 * Converts object with key-value pairs
 * into query-param string
 *
 * @param {Object} params
 */
export const objectToQueryString = (params = {}) =>
  Object.keys(params)
    .map(param => `${param}=${params[param]}`)
    .join('&');

export const buildUrlWithCurrentLocation = param => {
  if (param) return `${window.location.pathname}${param}`;

  return window.location.pathname;
};

/**
 * Based on the current location and the string parameters provided
 * creates a new entry in the history without reloading the page.
 *
 * @param {String} param
 */
export const historyPushState = newUrl => {
  window.history.pushState({}, document.title, newUrl);
};

/**
 * Based on the current location and the string parameters provided
 * overwrites the current entry in the history without reloading the page.
 *
 * @param {String} param
 */
export const historyReplaceState = newUrl => {
  window.history.replaceState({}, document.title, newUrl);
};

/**
 * Returns true for a String value of "true" and false otherwise.
 * This is the opposite of Boolean(...).toString().
 * `parseBoolean` is idempotent.
 *
 * @param  {String} value
 * @returns {Boolean}
 */
export const parseBoolean = value => (value && value.toString()) === 'true';

export const BACKOFF_TIMEOUT = 'BACKOFF_TIMEOUT';

/**
 * @callback backOffCallback
 * @param {Function} next
 * @param {Function} stop
 */

/**
 * Back Off exponential algorithm
 * backOff :: (Function<next, stop>, Number) -> Promise<Any, Error>
 *
 * @param {backOffCallback} fn function to be called
 * @param {Number} timeout
 * @return {Promise<Any, Error>}
 * @example
 * ```
 *  backOff(function (next, stop) {
 *    // Let's perform this function repeatedly for 60s or for the timeout provided.
 *
 *    ourFunction()
 *      .then(function (result) {
 *        // continue if result is not what we need
 *        next();
 *
 *        // when result is what we need let's stop with the repetions and jump out of the cycle
 *        stop(result);
 *      })
 *      .catch(function (error) {
 *        // if there is an error, we need to stop this with an error.
 *        stop(error);
 *      })
 *  }, 60000)
 *  .then(function (result) {})
 *  .catch(function (error) {
 *    // deal with errors passed to stop()
 *  })
 * ```
 */
export const backOff = (fn, timeout = 60000) => {
  const maxInterval = 32000;
  let nextInterval = 2000;
  let timeElapsed = 0;

  return new Promise((resolve, reject) => {
    const stop = arg => (arg instanceof Error ? reject(arg) : resolve(arg));

    const next = () => {
      if (timeElapsed < timeout) {
        setTimeout(() => fn(next, stop), nextInterval);
        timeElapsed += nextInterval;
        nextInterval = Math.min(nextInterval + nextInterval, maxInterval);
      } else {
        reject(new Error(BACKOFF_TIMEOUT));
      }
    };

    fn(next, stop);
  });
};

export const createOverlayIcon = (iconPath, overlayPath) => {
  const faviconImage = document.createElement('img');

  return new Promise(resolve => {
    faviconImage.onload = () => {
      const size = 32;

      const canvas = document.createElement('canvas');
      canvas.width = size;
      canvas.height = size;

      const context = canvas.getContext('2d');
      context.clearRect(0, 0, size, size);
      context.drawImage(
        faviconImage,
        0,
        0,
        faviconImage.width,
        faviconImage.height,
        0,
        0,
        size,
        size,
      );

      const overlayImage = document.createElement('img');
      overlayImage.onload = () => {
        context.drawImage(
          overlayImage,
          0,
          0,
          overlayImage.width,
          overlayImage.height,
          0,
          0,
          size,
          size,
        );

        const faviconWithOverlayUrl = canvas.toDataURL();

        resolve(faviconWithOverlayUrl);
      };
      overlayImage.src = overlayPath;
    };
    faviconImage.src = iconPath;
  });
};

export const setFaviconOverlay = overlayPath => {
  const faviconEl = document.getElementById('favicon');

  if (!faviconEl) {
    return null;
  }

  const iconPath = faviconEl.getAttribute('data-original-href');

  return createOverlayIcon(iconPath, overlayPath).then(faviconWithOverlayUrl =>
    faviconEl.setAttribute('href', faviconWithOverlayUrl),
  );
};

export const setFavicon = faviconPath => {
  const faviconEl = document.getElementById('favicon');
  if (faviconEl && faviconPath) {
    faviconEl.setAttribute('href', faviconPath);
  }
};

export const resetFavicon = () => {
  const faviconEl = document.getElementById('favicon');

  if (faviconEl) {
    const originalFavicon = faviconEl.getAttribute('data-original-href');
    faviconEl.setAttribute('href', originalFavicon);
  }
};

export const setCiStatusFavicon = pageUrl =>
  axios
    .get(pageUrl)
    .then(({ data }) => {
      if (data && data.favicon) {
        return setFaviconOverlay(data.favicon);
      }
      return resetFavicon();
    })
    .catch(error => {
      resetFavicon();
      throw error;
    });

export const spriteIcon = (icon, className = '') => {
  const classAttribute = className.length > 0 ? `class="${className}"` : '';

  return `<svg ${classAttribute}><use xlink:href="${gon.sprite_icons}#${icon}" /></svg>`;
};

/**
 * This method takes in object with snake_case property names
 * and returns a new object with camelCase property names
 *
 * Reasoning for this method is to ensure consistent property
 * naming conventions across JS code.
 *
 * This method also supports additional params in `options` object
 *
 * @param {Object} obj - Object to be converted.
 * @param {Object} options - Object containing additional options.
 * @param {boolean} options.deep - FLag to allow deep object converting
 * @param {Array[]} dropKeys - List of properties to discard while building new object
 * @param {Array[]} ignoreKeyNames - List of properties to leave intact (as snake_case) while building new object
 */
export const convertObjectPropsToCamelCase = (obj = {}, options = {}) => {
  if (obj === null) {
    return {};
  }

  const initial = Array.isArray(obj) ? [] : {};
  const { deep = false, dropKeys = [], ignoreKeyNames = [] } = options;

  return Object.keys(obj).reduce((acc, prop) => {
    const result = acc;
    const val = obj[prop];

    // Drop properties from new object if
    // there are any mentioned in options
    if (dropKeys.indexOf(prop) > -1) {
      return acc;
    }

    // Skip converting properties in new object
    // if there are any mentioned in options
    if (ignoreKeyNames.indexOf(prop) > -1) {
      result[prop] = obj[prop];
      return acc;
    }

    if (deep && (isObject(val) || Array.isArray(val))) {
      result[convertToCamelCase(prop)] = convertObjectPropsToCamelCase(val, options);
    } else {
      result[convertToCamelCase(prop)] = obj[prop];
    }
    return acc;
  }, initial);
};

/**
 * Converts all the object keys to snake case
 *
 * @param {Object} obj    Object to transform
 * @returns {Object}
 */
// Follow up to add additional options param:
// https://gitlab.com/gitlab-org/gitlab/issues/39173
export const convertObjectPropsToSnakeCase = (obj = {}) =>
  obj
    ? Object.entries(obj).reduce(
        (acc, [key, value]) => ({ ...acc, [convertToSnakeCase(key)]: value }),
        {},
      )
    : {};

export const imagePath = imgUrl =>
  `${gon.asset_host || ''}${gon.relative_url_root || ''}/assets/${imgUrl}`;

export const addSelectOnFocusBehaviour = (selector = '.js-select-on-focus') => {
  // Click a .js-select-on-focus field, select the contents
  // Prevent a mouseup event from deselecting the input
  $(selector).on('focusin', function selectOnFocusCallback() {
    $(this)
      .select()
      .one('mouseup', e => {
        e.preventDefault();
      });
  });
};

/**
 * Method to round of values with decimal places
 * with provided precision.
 *
 * Taken from https://stackoverflow.com/a/7343013/414749
 *
 * Eg; roundOffFloat(3.141592, 3) = 3.142
 *
 * Refer to spec/javascripts/lib/utils/common_utils_spec.js for
 * more supported examples.
 *
 * @param {Float} number
 * @param {Number} precision
 */
export const roundOffFloat = (number, precision = 0) => {
  // eslint-disable-next-line no-restricted-properties
  const multiplier = Math.pow(10, precision);
  return Math.round(number * multiplier) / multiplier;
};

/**
 * Represents navigation type constants of the Performance Navigation API.
 * Detailed explanation see https://developer.mozilla.org/en-US/docs/Web/API/PerformanceNavigation.
 */
export const NavigationType = {
  TYPE_NAVIGATE: 0,
  TYPE_RELOAD: 1,
  TYPE_BACK_FORWARD: 2,
  TYPE_RESERVED: 255,
};

/**
 * Method to perform case-insensitive search for a string
 * within multiple properties and return object containing
 * properties in case there are multiple matches or `null`
 * if there's no match.
 *
 * Eg; Suppose we want to allow user to search using for a string
 *     within `iid`, `title`, `url` or `reference` props of a target object;
 *
 *     const objectToSearch = {
 *       "iid": 1,
 *       "title": "Error omnis quos consequatur ullam a vitae sed omnis libero cupiditate. &3",
 *       "url": "/groups/gitlab-org/-/epics/1",
 *       "reference": "&1",
 *     };
 *
 *    Following is how we call searchBy and the return values it will yield;
 *
 *    -  `searchBy('omnis', objectToSearch);`: This will return `{ title: ... }` as our
 *        query was found within title prop we only return that.
 *    -  `searchBy('1', objectToSearch);`: This will return `{ "iid": ..., "reference": ..., "url": ... }`.
 *    -  `searchBy('https://gitlab.com/groups/gitlab-org/-/epics/1', objectToSearch);`:
 *        This will return `{ "url": ... }`.
 *    -  `searchBy('foo', objectToSearch);`: This will return `null` as no property value
 *        matched with our query.
 *
 *    You can learn more about behaviour of this method by referring to tests
 *    within `spec/javascripts/lib/utils/common_utils_spec.js`.
 *
 * @param {string} query String to search for
 * @param {object} searchSpace Object containing properties to search in for `query`
 */
export const searchBy = (query = '', searchSpace = {}) => {
  const targetKeys = searchSpace !== null ? Object.keys(searchSpace) : [];

  if (!query || !targetKeys.length) {
    return null;
  }

  const normalizedQuery = query.toLowerCase();
  const matches = targetKeys
    .filter(item => {
      const searchItem = `${searchSpace[item]}`.toLowerCase();

      return (
        searchItem.indexOf(normalizedQuery) > -1 ||
        normalizedQuery.indexOf(searchItem) > -1 ||
        normalizedQuery === searchItem
      );
    })
    .reduce((acc, prop) => {
      const match = acc;
      match[prop] = searchSpace[prop];

      return acc;
    }, {});

  return Object.keys(matches).length ? matches : null;
};

/**
 * Checks if the given Label has a special syntax `::` in
 * it's title.
 *
 * Expected Label to be an Object with `title` as a key:
 *   { title: 'LabelTitle', ...otherProperties };
 *
 * @param {Object} label
 * @returns Boolean
 */
export const isScopedLabel = ({ title = '' }) => title.indexOf('::') !== -1;

window.gl = window.gl || {};
window.gl.utils = {
  ...(window.gl.utils || {}),
  getPagePath,
  isInGroupsPage,
  isInProjectPage,
  getProjectSlug,
  getGroupSlug,
  isInIssuePage,
  ajaxGet,
  rstrip,
  updateTooltipTitle,
  disableButtonIfEmptyField,
  handleLocationHash,
  isInViewport,
  parseUrl,
  parseUrlPathname,
  getUrlParamsArray,
  isMetaKey,
  isMetaClick,
  scrollToElement,
  getParameterByName,
  getSelectedFragment,
  insertText,
  nodeMatchesSelector,
  spriteIcon,
  imagePath,
};
