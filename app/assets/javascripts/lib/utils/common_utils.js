import $ from 'jquery';
import Cookies from 'js-cookie';
import axios from './axios_utils';
import { getLocationHash } from './url_utility';
import { convertToCamelCase } from './text_utility';
import { isObject } from './type_utility';

export const getPagePath = (index = 0) => $('body').attr('data-page').split(':')[index];

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
export const isInNoteablePage = () => isInIssuePage() || isInMRPage();
export const hasVueMRDiscussionsCookie = () => Cookies.get('vue_mr_discussions');

export const ajaxGet = url => axios.get(url, {
  params: { format: 'js' },
  responseType: 'text',
}).then(({ data }) => {
  $.globalEval(data);
});

export const rstrip = (val) => {
  if (val) {
    return val.replace(/\s+$/, '');
  }
  return val;
};

export const updateTooltipTitle = ($tooltipEl, newTitle) => $tooltipEl.attr('title', newTitle).tooltip('fixTitle');

export const disableButtonIfEmptyField = (fieldSelector, buttonSelector, eventName = 'input') => {
  const field = $(fieldSelector);
  const closestSubmit = field.closest('form').find(buttonSelector);
  if (rstrip(field.val()) === '') {
    closestSubmit.disable();
  }
  // eslint-disable-next-line func-names
  return field.on(eventName, function () {
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

  window.scrollBy(0, adjustment);
};

// Check if element scrolled into viewport from above or below
// Courtesy http://stackoverflow.com/a/7557433/414749
export const isInViewport = (el) => {
  const rect = el.getBoundingClientRect();

  return (
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <= window.innerHeight &&
    rect.right <= window.innerWidth
  );
};

export const parseUrl = (url) => {
  const parser = document.createElement('a');
  parser.href = url;
  return parser;
};

export const parseUrlPathname = (url) => {
  const parsedUrl = parseUrl(url);
  // parsedUrl.pathname will return an absolute path for Firefox and a relative path for IE11
  // We have to make sure we always have an absolute path.
  return parsedUrl.pathname.charAt(0) === '/' ? parsedUrl.pathname : `/${parsedUrl.pathname}`;
};

// We can trust that each param has one & since values containing & will be encoded
// Remove the first character of search as it is always ?
export const getUrlParamsArray = () => window.location.search.slice(1).split('&').map((param) => {
  const split = param.split('=');
  return [decodeURI(split[0]), split[1]].join('=');
});

export const isMetaKey = e => e.metaKey || e.ctrlKey || e.altKey || e.shiftKey;

// Identify following special clicks
// 1) Cmd + Click on Mac (e.metaKey)
// 2) Ctrl + Click on PC (e.ctrlKey)
// 3) Middle-click or Mouse Wheel Click (e.which is 2)
export const isMetaClick = e => e.metaKey || e.ctrlKey || e.which === 2;

export const scrollToElement = (element) => {
  let $el = element;
  if (!(element instanceof $)) {
    $el = $(element);
  }
  const top = $el.offset().top;
  const mrTabsHeight = $('.merge-request-tabs').height() || 0;
  const headerHeight = $('.navbar-gitlab').height() || 0;

  return $('body, html').animate({
    scrollTop: top - mrTabsHeight - headerHeight,
  }, 200);
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

export const getSelectedFragment = () => {
  const selection = window.getSelection();
  if (selection.rangeCount === 0) return null;
  const documentFragment = document.createDocumentFragment();
  for (let i = 0; i < selection.rangeCount; i += 1) {
    documentFragment.appendChild(selection.getRangeAt(i).cloneContents());
  }
  if (documentFragment.textContent.length === 0) return null;

  return documentFragment;
};

export const insertText = (target, text) => {
  // Firefox doesn't support `document.execCommand('insertText', false, text)` on textareas
  const selectionStart = target.selectionStart;
  const selectionEnd = target.selectionEnd;
  const value = target.value;

  const textBefore = value.substring(0, selectionStart);
  const textAfter = value.substring(selectionEnd, value.length);

  const insertedText = text instanceof Function ? text(textBefore, textAfter) : text;
  const newText = textBefore + insertedText + textAfter;

  // eslint-disable-next-line no-param-reassign
  target.value = newText;
  // eslint-disable-next-line no-param-reassign
  target.selectionStart = target.selectionEnd = selectionStart + insertedText.length;

  // Trigger autosave
  target.dispatchEvent(new Event('input'));

  // Trigger autosize
  const event = document.createEvent('Event');
  event.initEvent('autosize:update', true, false);
  target.dispatchEvent(event);
};

export const nodeMatchesSelector = (node, selector) => {
  const matches = Element.prototype.matches ||
    Element.prototype.matchesSelector ||
    Element.prototype.mozMatchesSelector ||
    Element.prototype.msMatchesSelector ||
    Element.prototype.oMatchesSelector ||
    Element.prototype.webkitMatchesSelector;

  if (matches) {
    return matches.call(node, selector);
  }

  // IE11 doesn't support `node.matches(selector)`

  let parentNode = node.parentNode;
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
export const normalizeHeaders = (headers) => {
  const upperCaseHeaders = {};

  Object.keys(headers || {}).forEach((e) => {
    upperCaseHeaders[e.toUpperCase()] = headers[e];
  });

  return upperCaseHeaders;
};

/**
  this will take in the getAllResponseHeaders result and normalize them
  this way we don't run into production issues when nginx gives us lowercased header keys
*/
export const normalizeCRLFHeaders = (headers) => {
  const headersObject = {};
  const headersArray = headers.split('\n');

  headersArray.forEach((header) => {
    const keyValue = header.split(': ');
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

  return query
    .split('&')
    .reduce((acc, element) => {
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
export const objectToQueryString = (params = {}) => Object.keys(params).map(param => `${param}=${params[param]}`).join('&');

export const buildUrlWithCurrentLocation = param => (param ? `${window.location.pathname}${param}` : window.location.pathname);

/**
 * Based on the current location and the string parameters provided
 * creates a new entry in the history without reloading the page.
 *
 * @param {String} param
 */
export const historyPushState = (newUrl) => {
  window.history.pushState({}, document.title, newUrl);
};

/**
 * Converts permission provided as strings to booleans.
 *
 * @param  {String} string
 * @returns {Boolean}
 */
export const convertPermissionToBoolean = permission => permission === 'true';

/**
 * Back Off exponential algorithm
 * backOff :: (Function<next, stop>, Number) -> Promise<Any, Error>
 *
 * @param {Function<next, stop>} fn function to be called
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
    const stop = arg => ((arg instanceof Error) ? reject(arg) : resolve(arg));

    const next = () => {
      if (timeElapsed < timeout) {
        setTimeout(() => fn(next, stop), nextInterval);
        timeElapsed += nextInterval;
        nextInterval = Math.min(nextInterval + nextInterval, maxInterval);
      } else {
        reject(new Error('BACKOFF_TIMEOUT'));
      }
    };

    fn(next, stop);
  });
};

export const setFavicon = (faviconPath) => {
  const faviconEl = document.getElementById('favicon');
  if (faviconEl && faviconPath) {
    faviconEl.setAttribute('href', faviconPath);
  }
};

export const resetFavicon = () => {
  const faviconEl = document.getElementById('favicon');
  const originalFavicon = faviconEl ? faviconEl.getAttribute('href') : null;
  if (faviconEl) {
    faviconEl.setAttribute('href', originalFavicon);
  }
};

export const setCiStatusFavicon = pageUrl =>
  axios.get(pageUrl)
    .then(({ data }) => {
      if (data && data.favicon) {
        setFavicon(data.favicon);
      } else {
        resetFavicon();
      }
    })
    .catch(resetFavicon);

export const spriteIcon = (icon, className = '') => {
  const classAttribute = className.length > 0 ? `class="${className}"` : '';

  return `<svg ${classAttribute}><use xlink:href="${gon.sprite_icons}#${icon}" /></svg>`;
};

/**
 * This method takes in object with snake_case property names
 * and returns new object with camelCase property names
 *
 * Reasoning for this method is to ensure consistent property
 * naming conventions across JS code.
 */
export const convertObjectPropsToCamelCase = (obj = {}, options = {}) => {
  if (obj === null) {
    return {};
  }

  const initial = Array.isArray(obj) ? [] : {};

  return Object.keys(obj).reduce((acc, prop) => {
    const result = acc;
    const val = obj[prop];

    if (options.deep && (isObject(val) || Array.isArray(val))) {
      result[convertToCamelCase(prop)] = convertObjectPropsToCamelCase(val, options);
    } else {
      result[convertToCamelCase(prop)] = obj[prop];
    }
    return acc;
  }, initial);
};

export const imagePath = imgUrl => `${gon.asset_host || ''}${gon.relative_url_root || ''}/assets/${imgUrl}`;

export const addSelectOnFocusBehaviour = (selector = '.js-select-on-focus') => {
  // Click a .js-select-on-focus field, select the contents
  // Prevent a mouseup event from deselecting the input
  $(selector).on('focusin', function selectOnFocusCallback() {
    $(this).select().one('mouseup', (e) => {
      e.preventDefault();
    });
  });
};

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
