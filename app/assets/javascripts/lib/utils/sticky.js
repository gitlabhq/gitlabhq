import { getCoveringElement, observeIntersectionOnce } from '~/lib/utils/viewport';
import { getScrollingElement } from '~/lib/utils/panels';

/**
 * Scrolls the panel so that the provided element is not covered by sticky elements
 *
 * @param {HTMLElement} element Element that should not be covered by sticky elements
 * @param {Number} maxIterations Limit scroll attempts for performance
 */
export const scrollPastCoveringElements = async (element, maxIterations = 10) => {
  for (let i = 0; i < maxIterations; i += 1) {
    // eslint-disable-next-line no-await-in-loop
    const coveringElement = await getCoveringElement(element);
    if (!coveringElement) return;

    // eslint-disable-next-line no-await-in-loop
    const coveringRect = (await observeIntersectionOnce(coveringElement)).intersectionRect;
    // eslint-disable-next-line no-await-in-loop
    const elementRect = (await observeIntersectionOnce(element)).intersectionRect;
    const scrollAmount = coveringRect.bottom - elementRect.top;

    // Prevent over-scrolling (Firefox/Safari may return stale IntersectionObserver rects)
    if (scrollAmount <= 0) return;

    getScrollingElement(element).scrollBy({ top: -scrollAmount, behavior: 'instant' });
  }
};
