import $ from 'jquery';
import { defer, memoize } from 'lodash';
import { contentTop } from './common_utils';

const DEFAULT_PANEL_SCROLL_CONTAINER_SELECTOR = '.js-static-panel-inner';
const DYNAMIC_PANEL_SCROLL_CONTAINER_SELECTOR = '.js-dynamic-panel-inner';

const getPanelScrollingElement = (contextElement) => {
  const staticPanel = contextElement?.closest(DEFAULT_PANEL_SCROLL_CONTAINER_SELECTOR);
  if (staticPanel) {
    return staticPanel;
  }

  const dynamicPanel = contextElement?.closest(DYNAMIC_PANEL_SCROLL_CONTAINER_SELECTOR);
  if (dynamicPanel) {
    return dynamicPanel;
  }

  // Return the default panel
  return (
    document.querySelector(DEFAULT_PANEL_SCROLL_CONTAINER_SELECTOR) || document.scrollingElement
  );
};

const getApplicationScrollingElement = (contextElement) => {
  if (window.gon?.features?.projectStudioEnabled) {
    // We still return `document.scrollingElement` for pages that don't have panels, like login or error pages
    return getPanelScrollingElement(contextElement) || document.scrollingElement;
  }
  return document.scrollingElement;
};

/**
 * Finds a known scrolling element according to the element provided.
 * If the element is not provided, it defaults to the default panel.
 *
 * If no panel is found, it returns document.scrollingElement.
 * If `projectStudioEnabled` is disabled, it returns the document.scrollingElement.
 *
 * It is memoized for results with the same element.
 *
 * @param {Element} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is used.
 */
export const getScrollingElement = memoize(getApplicationScrollingElement);

const getScrollBehavior = (behavior = 'smooth') => {
  if (behavior === 'smooth' && window.matchMedia(`(prefers-reduced-motion: reduce)`).matches) {
    // Check if user prefers reduced motion, return 'auto' if true, otherwise return 'smooth'.
    // This helps support accessibility preferences for users who experience motion sickness.
    return 'auto';
  }
  return behavior;
};

/**
 * Checks if container (or document if container is not found) is scrolled
 * down all the way to the bottom.
 *
 * @param {Element} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is used.
 * @returns {Boolean}
 */
export const isScrolledToBottom = (contextElement) => {
  // Use clientHeight to account for any horizontal scrollbar.
  const { scrollHeight, scrollTop, clientHeight } = getScrollingElement(contextElement);

  // scrollTop can be a float, so round up to next integer.
  return Math.ceil(scrollTop + clientHeight) >= scrollHeight;
};

/**
 * Checks if container (or document if container is not found) is scrolled to the top
 *
 * @param {Element} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is used.
 * @returns {Boolean}
 */
export const isScrolledToTop = (contextElement) => {
  const { scrollTop } = getScrollingElement(contextElement);

  return scrollTop === 0;
};

/**
 * Scroll to the bottom of the scrolling element.
 *
 * @param {Element} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is scrolled.
 */
export const scrollDown = (contextElement) => {
  const scrollingElement = getScrollingElement(contextElement);
  const { scrollHeight } = scrollingElement;

  scrollingElement.scrollTo({ top: scrollHeight });
};

/**
 * Scroll to the bottom of the scrolling element.
 *
 * @param {Element} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is scrolled.
 */
export const scrollUp = (contextElement) => {
  getScrollingElement(contextElement).scrollTo({ top: 0 });
};

/**
 * Scrolls to the top  of the scrolling element with smooth behavior, respecting user's motion preferences.
 *
 * @param {Element} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is scrolled.
 */
export const smoothScrollTop = (contextElement) => {
  getScrollingElement(contextElement).scrollTo({ top: 0, behavior: getScrollBehavior() });
};

/**
 * Scrolls to the provided location.
 *
 * @param {ScrollToOptions} options The options to pass to Element.scrollTo
 * @param {Element} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is scrolled.
 */
export const scrollTo = (options, contextElement) => {
  getScrollingElement(contextElement).scrollTo(options);
};

/**
 * Scrolls to the top of a particular element.
 *
 * @param {jQuery | HTMLElement | String} element The target jQuery element, HTML element, or query selector to scroll to.
 * @param {Object} [options={}] Object containing additional options.
 * @param {Number} [options.offset=0] Scroll offset.
 * @param {'smooth'|'auto'|'instant'} [options.behavior='smooth'] Scroll behavior. Defaults to `smooth` unless user has `prefers-reduced-motion: reduce` enabled
 * @param {HTMLElement | String} [options.parent] The parent HTML element or query selector to scroll.
 */
export const scrollToElement = (element, options = {}) => {
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
      const { offset = 0, parent } = options;
      const behavior = getScrollBehavior(options?.behavior);

      let scrollContainer = getScrollingElement(el);
      if (parent && typeof parent === 'string') {
        scrollContainer = document.querySelector(parent);
      } else if (parent) {
        scrollContainer = parent;
      }
      const y = el.getBoundingClientRect().top + scrollContainer.scrollTop + offset - contentTop();

      scrollContainer.scrollTo({ top: y, behavior });
    });
  }
};
