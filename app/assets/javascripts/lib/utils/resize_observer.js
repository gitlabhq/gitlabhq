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

  const containerEl = document.querySelector(container);
  const ro = createResizeObserver();

  function handleScroll() {
    if (skipProgrammaticScrollEvent) {
      skipProgrammaticScrollEvent = false;
      return;
    }
    currentScrollPosition = scrollContainerIsDocument ? window.scrollY : scrollContainer.scrollTop;
    userScrollOffset = currentScrollPosition - targetTop;
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

  function keepTargetAtTop() {
    if (document.activeElement !== document.body) return;

    const anchorEl = document.getElementById(targetId);
    if (!anchorEl) return;

    scrollContainer = ScrollParent(document.getElementById(targetId)) || document.documentElement;
    scrollContainerIsDocument = scrollContainer === document.documentElement;

    if (!scrollContainer) return;

    skipProgrammaticScrollEvent = true;

    const anchorTop = anchorEl.getBoundingClientRect().top;
    currentScrollPosition = scrollContainerIsDocument ? window.scrollY : scrollContainer.scrollTop;

    // Add scrollPosition as getBoundingClientRect is relative to viewport
    // Add the accumulated scroll offset to maintain relative position
    // subtract contentTop so it goes below sticky headers, rather than top of viewport
    targetTop = anchorTop - contentTop() + currentScrollPosition + userScrollOffset;

    scrollContainer.scrollTo({
      top: targetTop,
      behavior: 'instant',
    });

    if (!scrollListenerEnabled) {
      addScrollListener();
      scrollListenerEnabled = true;
    }
  }

  containerEl.addEventListener('ResizeUpdate', keepTargetAtTop);
  ro.observe(containerEl);

  return function cleanup() {
    // add a slight delay to this to allow for a final scroll to the
    // element once notes have finished
    setTimeout(() => {
      ro.unobserve(containerEl);
      containerEl.removeEventListener('ResizeUpdate', keepTargetAtTop);
      removeScrollListener();
    }, 100);
  };
}
