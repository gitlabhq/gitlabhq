import { memoize } from 'lodash';

const DEFAULT_PANEL_SCROLL_CONTAINER_SELECTOR = '.js-static-panel-inner';
const DYNAMIC_PANEL_SCROLL_CONTAINER_SELECTOR = '.js-dynamic-panel-inner';

export const getPanelElement = (contextElement) => {
  if (!contextElement) return null;
  return (
    contextElement.closest(
      [DEFAULT_PANEL_SCROLL_CONTAINER_SELECTOR, DYNAMIC_PANEL_SCROLL_CONTAINER_SELECTOR].join(','),
    ) || null
  );
};

const getPanelScrollingElement = (contextElement) => {
  return (
    getPanelElement(contextElement) ||
    document.querySelector(DEFAULT_PANEL_SCROLL_CONTAINER_SELECTOR) ||
    document.scrollingElement
  );
};

const getApplicationScrollingElement = (contextElement) => {
  // We return `document.scrollingElement` for pages that don't have panels, like login or error pages
  return getPanelScrollingElement(contextElement) || document.scrollingElement;
};

/**
 * Finds a known scrolling element according to the element provided.
 * If the element is not provided, it defaults to the default panel.
 *
 * If no panel is found, it returns document.scrollingElement.
 *
 * It is memoized for results with the same element.
 *
 * @param {HTMLElement} [contextElement] The element to find the scrolling element. If not provided, the default panel or document.scrollingElement is used.
 */
export const getScrollingElement = memoize(getApplicationScrollingElement);
