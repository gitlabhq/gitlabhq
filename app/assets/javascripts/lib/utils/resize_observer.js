import { contentTop } from './common_utils';
import { getScrollingElement } from './scroll_utils';

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

  // start listening to scroll after the first keepTargetAtTop call
  let scrollListenerEnabled = false;
  let intersectionObserver = null;

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

    targetTop = targetElement.getBoundingClientRect().top;
    userScrollOffset = targetTop - contentTop();
  }

  function addScrollListener() {
    scrollingElement.addEventListener('scroll', handleScroll, { passive: true });
  }

  function removeScrollListener() {
    scrollingElement.removeEventListener('scroll', handleScroll);
  }

  function setupIntersectionObserver() {
    intersectionObserver = new IntersectionObserver((entries) => {
      const [entry] = entries;

      // if element gets scrolled off screen then remove listeners
      if (!entry.isIntersecting) {
        // eslint-disable-next-line no-use-before-define
        cleanup();
      }
    });

    intersectionObserver.observe(targetElement);
  }

  function keepTargetAtTop() {
    // once the user has selected or focused on an element, skip auto-scrolling for them
    if (document.activeElement !== document.body) return;

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

    if (!scrollListenerEnabled) {
      addScrollListener();
      scrollListenerEnabled = true;
    }

    if (!intersectionObserver) {
      setupIntersectionObserver();
    }
  }

  function cleanup() {
    setTimeout(() => {
      ro.unobserve(containerEl);
      removeScrollListener();

      if (intersectionObserver) {
        intersectionObserver.unobserve(targetElement);
        intersectionObserver.disconnect();
      }
    }, 1000);
  }

  ro.observe(containerEl);

  return cleanup;
}
