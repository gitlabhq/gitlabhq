import { contentTop } from './common_utils';
import { findParentPanelScrollingEl } from './scroll_utils';

/**
 * Watches for change in size of a container element (e.g. for lazy-loaded images)
 * and scrolls the target note to the top of the content area.
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

  let targetElement = null;
  let targetTop = 0;
  let currentScrollPosition = 0;
  let userScrollOffset = 0;

  let hasCheckedForPanel = false;
  let scrollingElement;

  // start listening to scroll after the first keepTargetAtTop call
  let scrollListenerEnabled = false;
  let intersectionObserver = null;

  const containerEl = document.querySelector(container);

  function getScrollingElement() {
    const projectStudioEnabled = window.gon?.features?.projectStudioEnabled;

    if (projectStudioEnabled && hasCheckedForPanel) {
      return scrollingElement;
    }

    if (projectStudioEnabled && targetElement) {
      scrollingElement = findParentPanelScrollingEl(targetElement) || document.scrollingElement;
      hasCheckedForPanel = true;
    } else {
      scrollingElement = document.scrollingElement;
    }

    return scrollingElement;
  }

  let { scrollHeight } = getScrollingElement();

  const ro = new ResizeObserver((entries) => {
    entries.forEach(() => {
      scrollHeight = getScrollingElement().scrollHeight;
      // eslint-disable-next-line no-use-before-define
      keepTargetAtTop();
    });
  });

  function handleScroll() {
    const diff = getScrollingElement().scrollHeight - scrollHeight;
    if (Math.abs(diff) > 100) {
      return;
    }

    targetTop = targetElement.getBoundingClientRect().top;
    userScrollOffset = targetTop - contentTop();
  }

  function addScrollListener() {
    window.addEventListener('scroll', handleScroll, { passive: true });
  }

  function removeScrollListener() {
    window.removeEventListener('scroll', handleScroll);
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
    if (document.activeElement !== document.body) return;

    targetElement = document.getElementById(targetId);

    if (!targetElement) return;

    const anchorTop = targetElement.getBoundingClientRect().top;
    const scroller = getScrollingElement();

    currentScrollPosition = scroller.scrollTop;

    // Add scrollPosition as getBoundingClientRect is relative to viewport
    // Add the accumulated scroll offset to maintain relative position
    // subtract contentTop so it goes below sticky headers, rather than top of viewport
    targetTop = anchorTop + currentScrollPosition - userScrollOffset - contentTop();

    scroller.scrollTo({ top: targetTop, behavior: 'instant' });

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
