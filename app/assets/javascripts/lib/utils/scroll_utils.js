import $ from 'jquery';
import { defer } from 'lodash';
import { NO_SCROLL_TO_HASH_CLASS } from '~/lib/utils/constants';
import { getScrollingElement } from '~/lib/utils/panels';
import { contentTop } from './common_utils';

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
 * @param {HTMLElement} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is used.
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
 * @param {HTMLElement} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is used.
 * @returns {Boolean}
 */
export const isScrolledToTop = (contextElement) => {
  const { scrollTop } = getScrollingElement(contextElement);

  return scrollTop === 0;
};

/**
 * Scroll to the bottom of the scrolling element.
 *
 * @param {HTMLElement} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is scrolled.
 */
export const scrollDown = (contextElement) => {
  const scrollingElement = getScrollingElement(contextElement);
  const { scrollHeight } = scrollingElement;

  scrollingElement.scrollTo({ top: scrollHeight });
};

/**
 * Scroll to the bottom of the scrolling element.
 *
 * @param {HTMLElement} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is scrolled.
 */
export const scrollUp = (contextElement) => {
  getScrollingElement(contextElement).scrollTo({ top: 0 });
};

/**
 * Scrolls to the top  of the scrolling element with smooth behavior, respecting user's motion preferences.
 *
 * @param {HTMLElement} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is scrolled.
 */
export const smoothScrollTop = (contextElement) => {
  getScrollingElement(contextElement).scrollTo({ top: 0, behavior: getScrollBehavior() });
};

/**
 * Scrolls to the provided location.
 *
 * @param {ScrollToOptions} options The options to pass to Element.scrollTo
 * @param {HTMLElement} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is scrolled.
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

/**
 * Prevents scrolling to an element when clicking links with the URL fragment (a[href="#foo"])
 *
 * @param {PointerEvent} event Link click event
 */
export const preventScrollToFragment = (event) => {
  const link = event.target.closest('a[href]');
  if (!link) return;
  event.preventDefault();
  const hash = link.href.split('#')[1];
  const target = document.getElementById(hash);
  if (!target) return;
  target.classList.add(NO_SCROLL_TO_HASH_CLASS);
  const { scrollLeft, scrollTop } = getScrollingElement(link);
  // replaceHistory won't highlight the element
  window.location.hash = hash;
  scrollTo({ top: scrollTop, left: scrollLeft }, target);
};
