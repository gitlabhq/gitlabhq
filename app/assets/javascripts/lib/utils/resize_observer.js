import ScrollParent from 'scrollparent';
import { contentTop } from './common_utils';

export function createResizeObserver() {
  return new ResizeObserver((entries) => {
    entries.forEach((entry) => {
      entry.target.dispatchEvent(new CustomEvent(`ResizeUpdate`, { detail: { entry } }));
    });
  });
}

/**
 * Watches for change in size of a container element (e.g. for lazy-loaded images)
 * and scrolls the target note to the top of the content area.
 * Stops watching if the target element is scrolled out of viewport
 *
 * @param {Object} options
 * @param {string} options.targetId - id of element to scroll to
 * @param {string} options.container - Selector of element containing target
 * @param {Element} options.component - Element containing target
 *
 * @return {Function} - Cleanup function to stop watching
 */
export function scrollToTargetOnResize({
  targetId = window.location.hash.slice(1),
  container = '#content-body',
} = {}) {
  if (!targetId) return null;

  let scrollContainer;
  let scrollContainerIsDocument;

  let targetTop = 0;
  let currentScrollPosition = 0;
  let userScrollOffset = 0;

  // start listening to scroll after the first keepTargetAtTop call
  let scrollListenerEnabled = false;
  // can't tell difference between user and el.scrollTo, so use a flag
  let skipProgrammaticScrollEvent = false;

  let intersectionObserver = null;
  let targetElement = null;
  let contentTopValue = contentTop();

  const containerEl = document.querySelector(container);
  const ro = createResizeObserver();

  function handleScroll() {
    if (skipProgrammaticScrollEvent) {
      contentTopValue = contentTop();
      skipProgrammaticScrollEvent = false;
      return;
    }
    currentScrollPosition = scrollContainerIsDocument ? window.scrollY : scrollContainer.scrollTop;
    userScrollOffset = currentScrollPosition - targetTop - contentTopValue;
  }

  function addScrollListener() {
    if (scrollContainerIsDocument) {
      // For document scrolling, we need to listen to window
      window.addEventListener('scroll', handleScroll, { passive: true });
    } else {
      scrollContainer.addEventListener('scroll', handleScroll, { passive: true });
    }
  }

  function removeScrollListener() {
    if (scrollContainerIsDocument) {
      window.removeEventListener('scroll', handleScroll);
    } else {
      scrollContainer?.removeEventListener('scroll', handleScroll);
    }
  }

  function setupIntersectionObserver() {
    intersectionObserver = new IntersectionObserver(
      (entries) => {
        const [entry] = entries;

        // if element gets scrolled off screen then remove listeners
        if (!entry.isIntersecting) {
          // eslint-disable-next-line no-use-before-define
          cleanup();
        }
      },
      {
        root: scrollContainerIsDocument ? null : scrollContainer,
      },
    );

    intersectionObserver.observe(targetElement);
  }

  function keepTargetAtTop() {
    if (document.activeElement !== document.body) return;

    const anchorEl = document.getElementById(targetId);
    if (!anchorEl) {
      return;
    }

    scrollContainer = ScrollParent(document.getElementById(targetId)) || document.documentElement;
    scrollContainerIsDocument = scrollContainer === document.documentElement;

    if (!scrollContainer) {
      return;
    }

    skipProgrammaticScrollEvent = true;

    const anchorTop = anchorEl.getBoundingClientRect().top;
    currentScrollPosition = scrollContainerIsDocument ? window.scrollY : scrollContainer.scrollTop;

    // Add scrollPosition as getBoundingClientRect is relative to viewport
    // Add the accumulated scroll offset to maintain relative position
    // subtract contentTop so it goes below sticky headers, rather than top of viewport
    targetTop = anchorTop - contentTopValue + currentScrollPosition + userScrollOffset;

    scrollContainer.scrollTo({
      top: targetTop,
      behavior: 'instant',
    });

    if (!scrollListenerEnabled) {
      addScrollListener();
      scrollListenerEnabled = true;
    }

    if (!intersectionObserver) {
      targetElement = anchorEl;
      setupIntersectionObserver();
    }
  }

  function cleanup() {
    ro.unobserve(containerEl);
    containerEl.removeEventListener('ResizeUpdate', keepTargetAtTop);
    removeScrollListener();

    if (intersectionObserver) {
      intersectionObserver.unobserve(targetElement);
      intersectionObserver.disconnect();
    }
  }

  containerEl.addEventListener('ResizeUpdate', keepTargetAtTop);
  ro.observe(containerEl);

  return cleanup;
}
