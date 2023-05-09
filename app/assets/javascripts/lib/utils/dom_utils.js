import { has } from 'lodash';
import { isInIssuePage, isInMRPage, isInEpicPage } from './common_utils';

/**
 * Checks whether an element's content exceeds the element's width.
 *
 * @param element DOM element to check
 */
export const hasHorizontalOverflow = (element) =>
  Boolean(element && element.scrollWidth > element.offsetWidth);

export const addClassIfElementExists = (element, className) => {
  if (element) {
    element.classList.add(className);
  }
};

export const isInVueNoteablePage = () => isInIssuePage() || isInEpicPage() || isInMRPage();

export const canScrollUp = ({ scrollTop }, margin = 0) => scrollTop > margin;

export const canScrollDown = ({ scrollTop, offsetHeight, scrollHeight }, margin = 0) =>
  scrollTop + offsetHeight < scrollHeight - margin;

export const toggleContainerClasses = (containerEl, classList) => {
  if (containerEl) {
    // eslint-disable-next-line array-callback-return
    Object.entries(classList).map(([key, value]) => {
      if (value) {
        containerEl.classList.add(key);
      } else {
        containerEl.classList.remove(key);
      }
    });
  }
};

/**
 * Return a object mapping element dataset names to booleans.
 *
 * This is useful for data- attributes whose presense represent
 * a truthiness, no matter the value of the attribute. The absence of the
 * attribute represents  falsiness.
 *
 * This can be useful when Rails-provided boolean-like values are passed
 * directly to the HAML template, rather than cast to a string.
 *
 * @param {HTMLElement} element - The DOM element to inspect
 * @param {string[]} names - The dataset (i.e., camelCase) names to inspect
 * @returns {Object.<string, boolean>}
 */
export const parseBooleanDataAttributes = ({ dataset }, names) =>
  names.reduce((acc, name) => {
    acc[name] = has(dataset, name);

    return acc;
  }, {});

/**
 * Returns whether or not the provided element is currently visible.
 * This function operates identically to jQuery's `:visible` pseudo-selector.
 * Documentation for this selector: https://api.jquery.com/visible-selector/
 * Implementation of this selector: https://github.com/jquery/jquery/blob/d0ce00cdfa680f1f0c38460bc51ea14079ae8b07/src/css/hiddenVisibleSelectors.js#L8
 * @param {HTMLElement} element The element to test
 * @returns {Boolean} `true` if the element is currently visible, otherwise false
 */
export const isElementVisible = (element) =>
  Boolean(element.offsetWidth || element.offsetHeight || element.getClientRects().length);

export const getParents = (element) => {
  const parents = [];
  let parent = element.parentNode;

  do {
    parents.push(parent);
    parent = parent.parentNode;
  } while (parent);

  return parents;
};

export const getParentByTagName = (element, tagName) => {
  let parent = element.parentNode;

  do {
    if (parent.nodeName?.toLowerCase() === tagName?.toLowerCase()) {
      return parent;
    }

    parent = parent.parentElement;
  } while (parent);

  return undefined;
};

/**
 * This method takes a HTML element and an object of attributes
 * to save repeated calls to `setAttribute` when multiple
 * attributes need to be set.
 *
 * @param {HTMLElement} el
 * @param {Object} attributes
 */
export const setAttributes = (el, attributes) => {
  Object.keys(attributes).forEach((key) => {
    el.setAttribute(key, attributes[key]);
  });
};

/**
 * Get the height of the wrapper page element
 * This height can be used to determine where the highest element goes in a page
 * Useful for gl-drawer's header-height prop
 * @param {String} contentWrapperClass the content wrapper class
 * @returns {String} height in px
 */
export const getContentWrapperHeight = (contentWrapperClass) => {
  const wrapperEl = document.querySelector(contentWrapperClass);
  return wrapperEl ? `${wrapperEl.offsetTop}px` : '';
};

/**
 * Replaces comment nodes in a DOM tree with a different element
 * containing the text of the comment.
 *
 * @param {*} el
 * @param {*} tagName
 */
export const replaceCommentsWith = (el, tagName) => {
  const iterator = document.createNodeIterator(el, NodeFilter.SHOW_COMMENT);
  let commentNode = iterator.nextNode();

  while (commentNode) {
    const newNode = document.createElement(tagName);
    newNode.textContent = commentNode.textContent;

    commentNode.parentNode.replaceChild(newNode, commentNode);

    commentNode = iterator.nextNode();
  }
};
