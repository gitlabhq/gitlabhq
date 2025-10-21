import $ from 'jquery';
import { defer } from 'lodash';
import { contentTop } from './common_utils';

const SCROLL_CONTAINER_SELECTOR = '.js-static-panel-inner';

const getScrollContainer = () => {
  return document.querySelector(SCROLL_CONTAINER_SELECTOR);
};

/**
 * Checks if container (or document if container is not found) is scrolled
 * down all the way to the bottom
 *
 * @returns {Boolean}
 */
export const isScrolledToBottom = (scrollContainer = getScrollContainer()) => {
  // Use clientHeight to account for any horizontal scrollbar.
  const { scrollHeight, scrollTop, clientHeight } = scrollContainer || document.documentElement;

  // scrollTop can be a float, so round up to next integer.
  return Math.ceil(scrollTop + clientHeight) >= scrollHeight;
};

/**
 * Checks if container (or document if container is not found) is scrolled to the top
 *
 * @returns {Boolean}
 */
export const isScrolledToTop = (scrollContainer = getScrollContainer()) => {
  const { scrollTop } = scrollContainer || document.documentElement;

  return scrollTop === 0;
};

export const scrollDown = (scrollContainer = getScrollContainer()) => {
  if (scrollContainer) {
    scrollContainer.scrollTo({ top: scrollContainer.scrollHeight });
  } else {
    // eslint-disable-next-line no-restricted-properties
    window.scrollTo({ top: document.body.scrollHeight });
  }
};

export const scrollUp = (scrollContainer = getScrollContainer()) => {
  if (scrollContainer) {
    scrollContainer.scrollTo({ top: 0 });
  } else {
    // eslint-disable-next-line no-restricted-properties
    window.scrollTo({ top: 0 });
  }
};

/**
 * @param {Element} element The element to find the parent panel scrolling element for.
 * @returns {Element | null}
 */
export const findParentPanelScrollingEl = (element) => {
  if (!element) return null;
  const staticPanel = element.closest('.js-static-panel');
  if (staticPanel) {
    return staticPanel.querySelector('.js-static-panel-inner');
  }
  const dynamicPanel = element.closest('.js-dynamic-panel');
  if (dynamicPanel) {
    return dynamicPanel.querySelector('.js-dynamic-panel-inner');
  }
  return null;
};

/**
 * @param {ScrollToOptions} options The options to pass to Element.scrollTo
 * @param {Element} element The element to use when searching for the correct scrolling element
 */
export const scrollTo = (options, element) => {
  const scroller = findParentPanelScrollingEl(element) || window;
  scroller.scrollTo(options);
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
  if (window.gon?.features?.projectStudioEnabled) {
    scrollingEl = findParentPanelScrollingEl(el) || window;
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
      const scrollTop = scrollingEl.scrollTop ?? scrollingEl.pageYOffset;
      const y = el.getBoundingClientRect().top + scrollTop + offset - contentTop();

      if (parent && typeof parent === 'string') {
        scrollingEl = document.querySelector(parent);
      } else if (parent) {
        scrollingEl = parent;
      }

      scrollingEl.scrollTo({ top: y, behavior });
    });
  }
};

/**
 * Scrolls with smooth behavior, respecting user's motion preferences.
 * @param {ScrollToOptions} [options] - Additional scroll options
 */
export function smoothScrollTo(options) {
  // Check if user prefers reduced motion, return 'auto' if true, otherwise return 'smooth'.
  // This helps support accessibility preferences for users who experience motion sickness.
  const behavior = window.matchMedia(`(prefers-reduced-motion: reduce)`).matches
    ? 'auto'
    : 'smooth';

  // eslint-disable-next-line no-restricted-properties -- we should remove this method and move to `scrollTo`.
  window.scrollTo({ ...options, behavior });
}

/**
 * Scrolls to the top of the page with smooth behavior, respecting user's motion preferences.
 */
export function smoothScrollTop() {
  smoothScrollTo({ top: 0 });
}
