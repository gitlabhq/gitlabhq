/**
 * @module common-utils
 */

import { GlBreakpointInstance as breakpointInstance } from '@gitlab/ui/dist/utils';
import $ from 'jquery';
import { isFunction, defer, escape, partial, toLower } from 'lodash';
import Cookies from '~/lib/utils/cookies';
import { SCOPED_LABEL_DELIMITER } from '~/sidebar/components/labels/labels_select_widget/constants';
import { DEFAULT_CI_CONFIG_PATH, CI_CONFIG_PATH_EXTENSION } from '~/lib/utils/constants';
import { convertToCamelCase, convertToSnakeCase } from './text_utility';
import { isObject } from './type_utility';
import { getLocationHash } from './url_utility';

export const NO_SCROLL_TO_HASH_CLASS = 'js-no-scroll-to-hash';

export const getPagePath = (index = 0) => {
  const { page = '' } = document.body.dataset;
  return page.split(':')[index];
};

export const checkPageAndAction = (page, action) => {
  const pagePath = getPagePath(1);
  const actionPath = getPagePath(2);

  return pagePath === page && actionPath === action;
};

export const isInIncidentPage = () => checkPageAndAction('incidents', 'show');
export const isInIssuePage = () => checkPageAndAction('issues', 'show');
export const isInWorkItemPage = () => checkPageAndAction('work_items', 'show');
export const isInDesignPage = () => checkPageAndAction('issues', 'designs');
export const isInMRPage = () =>
  checkPageAndAction('merge_requests', 'show') ||
  checkPageAndAction('merge_requests', 'diffs') ||
  checkPageAndAction('merge_requests', 'rapid_diffs') ||
  checkPageAndAction('merge_requests', 'reports');
export const isInEpicPage = () => checkPageAndAction('epics', 'show');

export const getDashPath = (path = window.location.pathname) => path.split('/-/')[1] || null;

export const rstrip = (val) => {
  if (val) {
    return val.replace(/\s+$/, '');
  }
  return val;
};

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

/**
 * Return the given element's offset height, or 0 if the element doesn't exist.
 * Probably not useful outside of handleLocationHash.
 *
 * @param {HTMLElement} element The element to measure.
 * @returns {number} The element's offset height.
 */
const getElementOffsetHeight = (element) => element?.offsetHeight ?? 0;

// automatically adjust scroll position for hash urls taking the height of the navbar into account
// https://github.com/twitter/bootstrap/issues/1768
export const handleLocationHash = () => {
  let hash = getLocationHash();
  if (!hash) return;

  // This is required to handle non-unicode characters in hash
  hash = decodeURIComponent(hash);

  const target = document.getElementById(hash) || document.getElementById(`user-content-${hash}`);

  // Allow targets to opt out of scroll behavior
  if (target?.classList.contains(NO_SCROLL_TO_HASH_CLASS)) return;

  const fixedTabs = document.querySelector('.js-tabs-affix');
  const fixedDiffStats = document.querySelector('.js-diff-files-changed');
  const headerLoggedOut = document.querySelector('.header-logged-out');
  const fixedTopBar = document.querySelector('.top-bar-fixed');
  const performanceBar = document.querySelector('#js-peek');
  const topPadding = 8;
  const diffFileHeader = document.querySelector('.js-file-title');
  const getFixedIssuableTitle = () => document.querySelector('.issue-sticky-header');
  const getMRStickyHeader = () => document.querySelector('.merge-request-sticky-header');
  const isIssuePage = isInIssuePage();
  const isEpicPage = isInEpicPage();
  const isWorkItemPage = isInWorkItemPage();

  let adjustment = 0;
  let fixedIssuableTitleOffset = 0;

  adjustment -= getElementOffsetHeight(headerLoggedOut);
  adjustment -= getElementOffsetHeight(fixedTabs);
  adjustment -= getElementOffsetHeight(fixedDiffStats);
  adjustment -= getElementOffsetHeight(fixedTopBar);
  adjustment -= getElementOffsetHeight(performanceBar);
  adjustment -= getElementOffsetHeight(diffFileHeader);

  if (isIssuePage) {
    adjustment -= topPadding;
    fixedIssuableTitleOffset = getElementOffsetHeight(getFixedIssuableTitle());
    adjustment -= fixedIssuableTitleOffset;
  }

  if (isInMRPage()) {
    adjustment -= topPadding;
    adjustment -= getElementOffsetHeight(getMRStickyHeader()) - getElementOffsetHeight(fixedTabs);
  }

  if (target?.scrollIntoView) {
    target.scrollIntoView(true);
  }

  setTimeout(() => {
    window.scrollBy(0, adjustment);
  });

  if (isIssuePage || isEpicPage || isWorkItemPage) {
    if (fixedIssuableTitleOffset === 0) {
      setTimeout(() => {
        fixedIssuableTitleOffset = -1 * getElementOffsetHeight(getFixedIssuableTitle());
        window.scrollBy(0, fixedIssuableTitleOffset);
      }, 200);
    }
  }
};

// Check if element scrolled into viewport from above or below
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

export const isElementClipped = (element, scrollContainer) => {
  const elementRect = element.getBoundingClientRect();
  const containerRect = scrollContainer.getBoundingClientRect();

  return (
    elementRect.top < containerRect.top ||
    elementRect.bottom > containerRect.bottom ||
    elementRect.left < containerRect.left ||
    elementRect.right > containerRect.right
  );
};

export const isModifierKey = (e) => e.metaKey || e.ctrlKey || e.altKey || e.shiftKey;

export const isMetaKey = (e) => e.metaKey || e.ctrlKey;

// Identify following special clicks
// 1) Cmd + Click on Mac (e.metaKey)
// 2) Ctrl + Click on PC (e.ctrlKey)
// 3) Middle-click or Mouse Wheel Click (e.which is 2)
export const isMetaClick = (e) => e.metaKey || e.ctrlKey || e.which === 2;

export const isMetaEnterKeyPair = (e) => isMetaKey(e) && e.key === 'Enter';

/**
 * Get the current computed outer height for given selector.
 */
export const getOuterHeight = (selector) => {
  const element = document.querySelector(selector);

  if (!element) {
    return 0;
  }

  return element.offsetHeight;
};

export const contentTop = () => {
  const isDesktop = breakpointInstance.isDesktop();
  const heightCalculators = [
    () => getOuterHeight('#js-peek'),
    () => getOuterHeight('.header-logged-out'),
    () => getOuterHeight('.top-bar-fixed'),
    ({ desktop }) => {
      const mrStickyHeader = document.querySelector('.merge-request-sticky-header');
      if (mrStickyHeader) {
        return mrStickyHeader.offsetHeight;
      }

      const container = document.querySelector('.discussions-counter');
      let size = 0;

      if (!desktop && container) {
        size = container.offsetHeight;
      }

      size += getOuterHeight('.merge-request-tabs');
      size += getOuterHeight('.issue-sticky-header.gl-fixed');

      return size;
    },
    () => getOuterHeight('.js-diff-files-changed'),
    ({ desktop }) => {
      const diffsTabIsActive = window.mrTabs?.currentAction === 'diffs';
      const isDiscussionScroll =
        desktop && diffsTabIsActive && window.location.hash.startsWith('#note');
      return isDiscussionScroll
        ? getOuterHeight('.diffs .diff-file .file-title-flex-parent:not([style="display:none"])')
        : 0;
    },
    ({ desktop }) => (desktop ? getOuterHeight('.mr-version-controls') : 0),
  ];

  return heightCalculators.reduce((totalHeight, calculator) => {
    return totalHeight + (calculator({ desktop: isDesktop }) || 0);
  }, 0);
};

/**
 * Scrolls to the top of a particular element.
 *
 * @param {jQuery | HTMLElement | String} element The target jQuery element, HTML element, or query selector to scroll to.
 * @param {Object} [options={}] Object containing additional options.
 * @param {Number} [options.duration=200] The scroll animation duration.
 * @param {Number} [options.offset=0] The scroll offset.
 * @param {String} [options.behavior=smooth|auto] The scroll animation behavior.
 * @param {HTMLElement | String} [options.parent] The parent HTML element or query selector to scroll.
 */
export const scrollToElement = (element, options = {}) => {
  let scrollingEl = window;
  let el = element;
  if (element instanceof $) {
    // eslint-disable-next-line prefer-destructuring
    el = element[0];
  } else if (typeof el === 'string') {
    el = document.querySelector(element);
  }

  if (el && el.getBoundingClientRect) {
    // In the previous implementation, jQuery naturally deferred this scrolling.
    // Unfortunately, we're quite coupled to this implementation detail now.
    defer(() => {
      const {
        duration = 200,
        offset = 0,
        behavior = duration ? 'smooth' : 'auto',
        parent,
      } = options;
      const y = el.getBoundingClientRect().top + window.pageYOffset + offset - contentTop();

      if (parent && typeof parent === 'string') {
        scrollingEl = document.querySelector(parent);
      } else if (parent) {
        scrollingEl = parent;
      }

      scrollingEl.scrollTo({ top: y, behavior });
    });
  }
};

export const scrollToElementWithContext = (element, options) => {
  const offsetMultiplier = -0.1;
  return scrollToElement(element, { ...options, offset: window.innerHeight * offsetMultiplier });
};

/**
 * Returns a function that can only be invoked once between
 * each browser screen repaint.
 * @param {Function} fn
 */
export const debounceByAnimationFrame = (fn) => {
  let requestId;

  return function debounced(...args) {
    if (requestId) {
      window.cancelAnimationFrame(requestId);
    }
    requestId = window.requestAnimationFrame(() => fn.apply(this, args));
  };
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

export const getSelectedFragment = (restrictToNode) => {
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

  if (documentFragment.textContent.length === 0 && documentFragment.children.length === 0) {
    return null;
  }

  return documentFragment;
};

function execInsertText(text, hasSelection) {
  if (text !== '') {
    return document.execCommand('insertText', false, text);
  }

  if (hasSelection) {
    return document.execCommand('delete');
  }

  // Nothing to do :)
  return true;
}

/**
 * This method inserts text into a textarea/input field.
 * Uses `execCommand` if supported
 *
 * @param {HTMLElement} target - textarea/input to have text inserted into
 * @param {String | function} text - text to be inserted
 */
export const insertText = (target, text) => {
  const { selectionStart, selectionEnd, value } = target;
  const textBefore = value.substring(0, selectionStart);
  const textAfter = value.substring(selectionEnd, value.length);
  const insertedText = text instanceof Function ? text(textBefore, textAfter) : text;
  const hasSelection = selectionEnd !== selectionStart;

  // The `execCommand` is officially deprecated.  However, for `insertText`,
  // there is currently no alternative. We need to use it in order to trigger
  // the browser's undo tracking when we insert text.
  // Per https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand on 2022-04-11,
  //   The Clipboard API can be used instead of execCommand in many cases,
  //   but execCommand is still sometimes useful. In particular, the Clipboard
  //   API doesn't replace the insertText command
  // So we attempt to use it if possible. Otherwise, fall back to just replacing
  // the value as before. In this case, Undo will be broken with inserted text.
  // Testing on older versions of Firefox:
  //   87 and below: does not work and falls through to just replacing value.
  //     87 was released in Mar of 2021
  //   89 and above: works well
  //     89 was released in May of 2021
  if (!execInsertText(insertedText, hasSelection)) {
    const newText = textBefore + insertedText + textAfter;

    // eslint-disable-next-line no-param-reassign
    target.value = newText;

    // eslint-disable-next-line no-param-reassign
    target.selectionStart = selectionStart + insertedText.length;

    // eslint-disable-next-line no-param-reassign
    target.selectionEnd = selectionStart + insertedText.length;
  }

  // Trigger autosave
  target.dispatchEvent(new Event('input'));

  // Trigger autosize
  const event = document.createEvent('Event');
  event.initEvent('autosize:update', true, false);
  target.dispatchEvent(event);
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
 * Parses pagination object string values into numbers.
 *
 * @param {Object} paginationInformation
 * @returns {Object}
 */
export const parseIntPagination = (paginationInformation) => ({
  perPage: parseInt(paginationInformation['X-PER-PAGE'], 10),
  page: parseInt(paginationInformation['X-PAGE'], 10),
  total: parseInt(paginationInformation['X-TOTAL'], 10),
  totalPages: parseInt(paginationInformation['X-TOTAL-PAGES'], 10),
  nextPage: parseInt(paginationInformation['X-NEXT-PAGE'], 10),
  previousPage: parseInt(paginationInformation['X-PREV-PAGE'], 10),
});

export const buildUrlWithCurrentLocation = (param) => {
  if (param) return `${window.location.pathname}${param}`;

  return window.location.pathname;
};

/**
 * Based on the current location and the string parameters provided
 * creates a new entry in the history without reloading the page.
 *
 * @param {String} param
 */
export const historyPushState = (newUrl, state = {}) => {
  window.history.pushState(state, document.title, newUrl);
};

/**
 * Based on the current location and the string parameters provided
 * overwrites the current entry in the history without reloading the page.
 *
 * @param {String} param
 */
export const historyReplaceState = (newUrl) => {
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
export const parseBoolean = (value) => (value && value.toString()) === 'true';

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
    const stop = (arg) => (arg instanceof Error ? reject(arg) : resolve(arg));

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

export const spriteIcon = (icon, className = '') => {
  const classAttribute = className.length > 0 ? `class="${className}"` : '';

  return `<svg ${classAttribute}><use xlink:href="${gon.sprite_icons}#${escape(icon)}" /></svg>`;
};

/**
 * @callback ConversionFunction
 * @param {string} prop
 */

/**
 * This function takes a conversion function as the first parameter
 * and applies this function to each prop in the provided object.
 *
 * This method also supports additional params in `options` object
 *
 * @param {ConversionFunction} conversionFunction - Function to apply to each prop of the object.
 * @param {Object} obj - Object to be converted.
 * @param {Object} options - Object containing additional options.
 * @param {boolean} options.deep - FLag to allow deep object converting
 * @param {Array[]} options.dropKeys - List of properties to discard while building new object
 * @param {Array[]} options.ignoreKeyNames - List of properties to leave intact (as snake_case) while building new object
 */
export const convertObjectProps = (conversionFunction, obj = {}, options = {}) => {
  if (!isFunction(conversionFunction) || obj === null) {
    return {};
  }

  const { deep = false, dropKeys = [], ignoreKeyNames = [] } = options;

  const isObjParameterArray = Array.isArray(obj);
  const initialValue = isObjParameterArray ? [] : {};

  return Object.keys(obj).reduce((acc, prop) => {
    const val = obj[prop];

    // Drop properties from new object if
    // there are any mentioned in options
    if (dropKeys.indexOf(prop) > -1) {
      return acc;
    }

    // Skip converting properties in new object
    // if there are any mentioned in options
    if (ignoreKeyNames.indexOf(prop) > -1) {
      acc[prop] = val;
      return acc;
    }

    if (deep && (isObject(val) || Array.isArray(val))) {
      if (isObjParameterArray) {
        acc[prop] = convertObjectProps(conversionFunction, val, options);
      } else {
        acc[conversionFunction(prop)] = convertObjectProps(conversionFunction, val, options);
      }
    } else if (isObjParameterArray) {
      acc[prop] = val;
    } else {
      acc[conversionFunction(prop)] = val;
    }
    return acc;
  }, initialValue);
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
 * @param {Array[]} options.dropKeys - List of properties to discard while building new object
 * @param {Array[]} options.ignoreKeyNames - List of properties to leave intact (as snake_case) while building new object
 */
export const convertObjectPropsToCamelCase = (obj = {}, options = {}) =>
  convertObjectProps(convertToCamelCase, obj, options);

/**
 * This method returns a new object with lowerCase property names
 *
 * Reasoning for this method is to ensure consistent access for some
 * sort of objects
 *
 * This method also supports additional params in `options` object
 *
 * @param {Object} obj - Object to be converted.
 * @param {Object} options - Object containing additional options.
 * @param {boolean} options.deep - FLag to allow deep object converting
 * @param {Array[]} options.dropKeys - List of properties to discard while building new object
 * @param {Array[]} options.ignoreKeyNames - List of properties to leave intact while building new object
 */
export const convertObjectPropsToLowerCase = partial(convertObjectProps, toLower);

/**
 * Converts all the object keys to snake case
 *
 * This method also supports additional params in `options` object
 *
 * @param {Object} obj - Object to be converted.
 * @param {Object} options - Object containing additional options.
 * @param {boolean} options.deep - FLag to allow deep object converting
 * @param {Array[]} options.dropKeys - List of properties to discard while building new object
 * @param {Array[]} options.ignoreKeyNames - List of properties to leave intact (as snake_case) while building new object
 */
export const convertObjectPropsToSnakeCase = (obj = {}, options = {}) =>
  convertObjectProps(convertToSnakeCase, obj, options);

export const addSelectOnFocusBehaviour = (selector = '.js-select-on-focus') => {
  // Click a .js-select-on-focus field, select the contents
  // Prevent a mouseup event from deselecting the input
  $(selector).on('focusin', function selectOnFocusCallback() {
    $(this)
      .select()
      .one('mouseup', (e) => {
        e.preventDefault();
      });
  });
};

/**
 * Method to round of values with decimal places
 * with provided precision.
 *
 * Eg; roundOffFloat(3.141592, 3) = 3.142
 *
 * Refer to spec/frontend/lib/utils/common_utils_spec.js for
 * more supported examples.
 *
 * @param {Float} number
 * @param {Number} precision
 */
export const roundOffFloat = (number, precision = 0) => {
  const multiplier = 10 ** precision;
  return Math.round(number * multiplier) / multiplier;
};

/**
 * Method to round values to the nearest half (0.5)
 *
 * Eg; roundToNearestHalf(3.141592) = 3, roundToNearestHalf(3.41592) = 3.5
 *
 * Refer to spec/frontend/lib/utils/common_utils_spec.js for
 * more supported examples.
 *
 * @param {Float} number
 * @returns {Float|Number}
 */
export const roundToNearestHalf = (num) => Math.round(num * 2).toFixed() / 2;

/**
 * Method to round down values with decimal places
 * with provided precision.
 *
 * Eg; roundDownFloat(3.141592, 3) = 3.141
 *
 * Refer to spec/frontend/lib/utils/common_utils_spec.js for
 * more supported examples.
 *
 * @param {Float} number
 * @param {Number} precision
 */
export const roundDownFloat = (number, precision = 0) => {
  const multiplier = 10 ** precision;
  return Math.floor(number * multiplier) / multiplier;
};

/**
 * Represents navigation type constants of the Performance Navigation API.
 * Detailed explanation see https://developer.mozilla.org/en-US/docs/Web/API/PerformanceNavigation.
 */
export const navigationType = {
  TYPE_NAVIGATE: 0,
  TYPE_RELOAD: 1,
  TYPE_BACK_FORWARD: 2,
  TYPE_RESERVED: 255,
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
export const isScopedLabel = ({ title = '', name = '' } = {}) =>
  title.includes(SCOPED_LABEL_DELIMITER) || name.includes(SCOPED_LABEL_DELIMITER);

const scopedLabelRegex = new RegExp(`(.*)${SCOPED_LABEL_DELIMITER}.*`);

/**
 * Returns the key of a scoped label.
 * For example:
 * - returns `scoped` if the label is `scoped::value`.
 * - returns `scoped::label` if the label is `scoped::label::value`.
 *
 * @param {Object} label object containing `title` property
 * @returns String scoped label key, or full label if it is not a scoped label
 */
export const scopedLabelKey = ({ title = '' }) => {
  return title.replace(scopedLabelRegex, '$1');
};

// Methods to set and get Cookie
export const setCookie = (name, value, attributes) => {
  const defaults = { expires: 365, secure: Boolean(window.gon?.secure) };
  Cookies.set(name, value, { ...defaults, ...attributes });
};

export const getCookie = (name) => Cookies.get(name);

export const removeCookie = (name) => Cookies.remove(name);

/**
 * This method takes in array with snake_case strings
 * and returns a new array with camelCase strings
 *
 * @param {Array[String]} array - Array to be converted
 * @returns {Array[String]} Converted array
 */
export const convertArrayToCamelCase = (array) => array.map((i) => convertToCamelCase(i));

export const isLoggedIn = () => Boolean(window.gon?.current_user_id);

/**
 * This method takes in array of objects with snake_case
 * property names and returns a new array of objects with
 * camelCase property names
 *
 * @param {Array[Object]} array - Array to be converted
 * @returns {Array[Object]} Converted array
 */
export const convertArrayOfObjectsToCamelCase = (array) =>
  array.map((o) => convertObjectPropsToCamelCase(o));

export const getFirstPropertyValue = (data) => {
  if (!data) return null;

  const [key] = Object.keys(data);
  if (!key) return null;

  return data[key];
};

export const isCurrentUser = (userId) => {
  const currentUserId = window.gon?.current_user_id;

  if (!currentUserId) {
    return false;
  }

  return Number(userId) === currentUserId;
};

/**
 * Clones an object via JSON stringifying and re-parsing.
 * This ensures object references are not persisted (e.g. unlike lodash cloneDeep)
 */
export const cloneWithoutReferences = (obj) => {
  return JSON.parse(JSON.stringify(obj));
};

/**
 * Returns true if the given path is the default CI config path.
 */
export const isDefaultCiConfig = (path) => {
  return path === DEFAULT_CI_CONFIG_PATH;
};

/**
 * Returns true if the given path has the CI config path extension.
 */
export const hasCiConfigExtension = (path) => {
  return CI_CONFIG_PATH_EXTENSION.test(path);
};

/**
 * Checks if an element with position:sticky is stuck
 *
 * @param el
 * @returns {boolean}
 */
export const isElementStuck = (el) =>
  el.getBoundingClientRect().top <= parseInt(getComputedStyle(el).top, 10);
