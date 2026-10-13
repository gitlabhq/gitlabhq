import { getScrollingElement } from '~/lib/utils/panels';
import { contentTop } from './common_utils';

/**
 * Watches for change in size of a container element
 * (e.g. lazy-loaded images or paginated notes)
 * and scrolls the target note to the top of the content area.
 *
 * Stops watching if the target element is scrolled out of viewport
 *
 * @param {Object} options
 * @param {string} options.targetId - id of element to scroll to
 * @param {string} options.container - Selector of element containing target
 *
 * @return {Function} - Cleanup function to stop watching
 */
export function scrollToTargetOnResize({
  targetId = window.location.hash.slice(1),
  container = '#content-body',
} = {}) {
  if (!targetId) return null;

  const containerEl = document.querySelector(container);
  const scrollingElement = getScrollingElement(containerEl);

  let targetElement = null;
  let targetTop = 0;
  let currentScrollPosition = 0;
  let userScrollOffset = 0;
  let ownScrollTop = null;

  // start listening to scroll after the first keepTargetAtTop call
  let scrollListenerEnabled = false;
  let intersectionObserver = null;
  let observedElement = null;

  let { scrollHeight } = scrollingElement;

  const ro = new ResizeObserver((entries) => {
    entries.forEach(() => {
      scrollHeight = scrollingElement.scrollHeight;
      // eslint-disable-next-line no-use-before-define
      keepTargetAtTop();
    });
  });

  function handleScroll() {
    const diff = scrollingElement.scrollHeight - scrollHeight;
    if (Math.abs(diff) > 100) {
      return;
    }

    if (scrollingElement.scrollTop === ownScrollTop) return;
    ownScrollTop = null;

    // A replaced node reads as all zeros until the next resize finds the new one
    if (!targetElement?.isConnected) return;

    targetTop = targetElement.getBoundingClientRect().top;
    userScrollOffset = targetTop - contentTop();
  }

  function addScrollListener() {
    scrollingElement.addEventListener('scroll', handleScroll, { passive: true });
  }

  function removeScrollListener() {
    scrollingElement.removeEventListener('scroll', handleScroll);
  }

  function observeTarget() {
    if (!intersectionObserver) {
      intersectionObserver = new IntersectionObserver((entries) => {
        // Vue replaces the target node as notes load, and a detached node also reports
        // isIntersecting: false. Only a connected node means the user scrolled it away.
        if (entries.some((entry) => entry.target.isConnected && !entry.isIntersecting)) {
          // eslint-disable-next-line no-use-before-define
          cleanup();
        }
      });
    }

    if (observedElement === targetElement) return;

    if (observedElement) intersectionObserver.unobserve(observedElement);
    intersectionObserver.observe(targetElement);
    observedElement = targetElement;
  }

  function keepTargetAtTop() {
    const superTopbar = document.querySelector('.js-super-topbar');

    // once the user has selected or focused on an element, skip auto-scrolling for them
    if (![document.body, superTopbar].includes(document.activeElement)) return;

    targetElement = document.getElementById(targetId);

    // skip if the element hasn't loaded yet
    if (!targetElement) return;

    const anchorTop = targetElement.getBoundingClientRect().top;

    currentScrollPosition = scrollingElement.scrollTop;

    // Add scrollPosition as getBoundingClientRect is relative to viewport
    // Add the accumulated scroll offset to maintain relative position
    // subtract contentTop so it goes below sticky headers, rather than top of viewport
    targetTop = anchorTop + currentScrollPosition - userScrollOffset - contentTop();

    scrollingElement.scrollTo({ top: targetTop, behavior: 'instant' });
    // The browser clamps targetTop to the max scroll, so read back where it landed
    ownScrollTop = scrollingElement.scrollTop;

    if (!scrollListenerEnabled) {
      addScrollListener();
      scrollListenerEnabled = true;
    }

    observeTarget();
  }

  function cleanup() {
    setTimeout(() => {
      ro.unobserve(containerEl);
      removeScrollListener();

      if (intersectionObserver) {
        intersectionObserver.unobserve(observedElement);
        intersectionObserver.disconnect();
      }
    }, 1000);
  }

  ro.observe(containerEl);

  return cleanup;
}
