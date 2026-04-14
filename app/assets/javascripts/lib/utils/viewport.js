const TOOLTIP_SELECTOR = '[role="tooltip"]';

/**
 * Executes a callback with all tooltips temporarily hidden,
 * ensuring elementFromPoint-based measurements are not affected by tooltip overlays.
 *
 * @param {Function} fn Callback to execute while tooltips are hidden
 * @returns {*} The return value of the callback
 */
export function withHiddenTooltips(fn) {
  const tooltips = Array.from(document.querySelectorAll(TOOLTIP_SELECTOR)).filter(
    (el) => getComputedStyle(el).display !== 'none',
  );
  tooltips.forEach((el) => {
    el.style.setProperty('display', 'none', 'important');
  });
  try {
    return fn();
  } finally {
    tooltips.forEach((el) => {
      el.style.removeProperty('display');
    });
  }
}

export const observeIntersectionOnce = (element) => {
  return new Promise((resolve) => {
    const observer = new IntersectionObserver(([entry]) => {
      resolve(entry);
      observer.disconnect();
    });
    observer.observe(element);
  });
};

/**
 * Given a target element and the coordinates of its top-left corner,
 * returns the sticky/fixed element covering it, or null.
 */
export const findCoveringElementAtPoint = (element, left, top) => {
  // browser might compensate for sticky element border, we should shift the target by 1px because of this
  const topElement = document.elementFromPoint(left, top + 1);

  if (!topElement || topElement === element || element.contains(topElement)) return null;

  let current = topElement;
  while (current && current !== document.body) {
    const { position } = getComputedStyle(current);
    if (position === 'sticky' || position === 'fixed') return current;
    current = current.offsetParent;
  }

  return null;
};

export const getCoveringElementSync = (element) => {
  const { top, left } = element.getBoundingClientRect();
  return findCoveringElementAtPoint(element, left, top);
};

export const getCoveringElement = async (element) => {
  const { top, left } = (await observeIntersectionOnce(element)).intersectionRect;
  return findCoveringElementAtPoint(element, left, top);
};
