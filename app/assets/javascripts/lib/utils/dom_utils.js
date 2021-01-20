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
 * a truthiness, no matter the value of the attribute. The absense of the
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

/**
 * The opposite of `isElementVisible`.
 * Returns whether or not the provided element is currently hidden.
 * This function operates identically to jQuery's `:hidden` pseudo-selector.
 * Documentation for this selector: https://api.jquery.com/hidden-selector/
 * Implementation of this selector: https://github.com/jquery/jquery/blob/d0ce00cdfa680f1f0c38460bc51ea14079ae8b07/src/css/hiddenVisibleSelectors.js#L6
 * @param {HTMLElement} element The element to test
 * @returns {Boolean} `true` if the element is currently hidden, otherwise false
 */
export const isElementHidden = (element) => !isElementVisible(element);
