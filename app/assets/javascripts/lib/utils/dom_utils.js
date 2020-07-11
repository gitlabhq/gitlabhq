import { has } from 'lodash';
import { isInIssuePage, isInMRPage, isInEpicPage } from './common_utils';

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
