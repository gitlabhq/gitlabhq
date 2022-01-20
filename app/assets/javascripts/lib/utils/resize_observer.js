import { contentTop } from './common_utils';

const interactionEvents = ['mousedown', 'touchstart', 'keydown', 'wheel'];

export function createResizeObserver() {
  return new ResizeObserver((entries) => {
    entries.forEach((entry) => {
      entry.target.dispatchEvent(new CustomEvent(`ResizeUpdate`, { detail: { entry } }));
    });
  });
}

// watches for change in size of a container element (e.g. for lazy-loaded images)
// and scroll the target element to the top of the content area
// stop watching after any user input. So if user opens sidebar or manually
// scrolls the page we don't hijack their scroll position
export function scrollToTargetOnResize({
  target = window.location.hash,
  container = '#content-body',
} = {}) {
  if (!target) return null;

  const ro = createResizeObserver();
  const containerEl = document.querySelector(container);
  let interactionListenersAdded = false;

  function keepTargetAtTop() {
    const anchorEl = document.querySelector(target);

    if (!anchorEl) return;

    const anchorTop = anchorEl.getBoundingClientRect().top + window.scrollY;
    const top = anchorTop - contentTop();
    document.documentElement.scrollTo({
      top,
    });

    if (!interactionListenersAdded) {
      interactionEvents.forEach((event) =>
        // eslint-disable-next-line no-use-before-define
        document.addEventListener(event, removeListeners),
      );
      interactionListenersAdded = true;
    }
  }

  function removeListeners() {
    interactionEvents.forEach((event) => document.removeEventListener(event, removeListeners));

    ro.unobserve(containerEl);
    containerEl.removeEventListener('ResizeUpdate', keepTargetAtTop);
  }

  containerEl.addEventListener('ResizeUpdate', keepTargetAtTop);

  ro.observe(containerEl);
  return ro;
}
