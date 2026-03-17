/**
 * Utilities for lazy rendering components using IntersectionObserver.
 * These utilities help optimize performance by only rendering items
 * that are visible in the viewport.
 */

/**
 * Creates an IntersectionObserver that toggles item visibility based on viewport intersection.
 * @param {Function} setItemVisibility - Callback to update item visibility (itemId, isVisible)
 * @param {object} options - Observer options
 * @param {HTMLElement|null} options.rootElement - The root element for the observer (null for viewport)
 * @param {string} options.scrollMargin - Margin around the root to pre-render items before they enter viewport
 * @param {boolean} options.once - If true, items are only observed until they first appear (one-way "appeared" pattern)
 * @returns {IntersectionObserver}
 */
export const createItemVisibilityObserver = (
  setItemVisibility,
  { rootElement = null, scrollMargin = '1500px', once = false } = {},
) => {
  const observer = new IntersectionObserver(
    (entries) =>
      entries?.forEach(({ target, isIntersecting }) => {
        if (once && !isIntersecting) return;
        setItemVisibility(target.dataset?.itemId, isIntersecting);
        const isFocussed =
          target.querySelector('[data-placeholder-item]') === document.activeElement;
        if (isIntersecting && isFocussed)
          requestAnimationFrame(() => target.querySelector('button')?.focus());
        if (once && isIntersecting) observer.unobserve(target);
      }),
    {
      root: rootElement,
      scrollMargin, // Pre-render items before scrolling into view (prevent white flashing)
    },
  );
  return observer;
};

/**
 * Observes all elements matching the selector within a container.
 * @param {HTMLElement} container - Container element to query within
 * @param {IntersectionObserver} observer - The observer instance
 * @param {string} selector - CSS selector for elements to observe
 */
export const observeElements = (container, observer, selector = '[data-item-id]') =>
  container?.querySelectorAll(selector).forEach((el) => observer?.observe(el));

/**
 * Observes specific elements by their data-item-id attribute within a container.
 * @param {HTMLElement} container - Container element to query within
 * @param {IntersectionObserver} observer - The observer instance
 * @param {string[]} ids - Array of item IDs to observe
 */
export const observeElementsByIds = (container, observer, ids) => {
  const idSet = new Set(ids);
  container?.querySelectorAll('[data-item-id]').forEach((el) => {
    if (idSet.has(el.dataset.itemId)) observer?.observe(el);
  });
};
